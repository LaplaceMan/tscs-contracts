/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-07 17:56:09
 * @Description: 基于区块链的代币化字幕众包系统 - Murmes
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/IGuard.sol";
import "./base/StrategyManager.sol";

contract Murmes is StrategyManager {
    /**
     * @notice Murmes 内已经发出的申请（任务）总数
     */
    uint256 public totalTasks;

    /**
     * @notice 每个申请都有一个相应的 Application 结构记录申请信息
     * @param applicant 发出申请, 需求制作字幕服务的用户
     * @param videoId 申请所属视频的 ID
     * @param strategy 结算策略
     * @param amount 支付金额/比例
     * @param language 申请所需语言的 ID
     * @param subtitles 申请下已上传字幕的 ID 集合
     * @param adopted 最终被采纳字幕的 ID
     * @param deadline 结算策略为 0 时, 超过该期限可提取费用, 其它策略为申请冻结
     */
    struct Application {
        address applicant;
        address platform;
        uint256 videoId;
        string source;
        uint8 strategy;
        uint256 amount;
        uint32 language;
        uint256[] subtitles;
        uint256 adopted;
        uint256 deadline;
    }

    constructor(address dao, address mutliSig) {
        _setOwner(dao);
        _setMutliSig(mutliSig);
        languageNote.push("Default");
    }

    /**
     * @notice taskId 与 Application 的映射, 从 1 开始（发出申请的顺位）
     */
    mapping(uint256 => Application) public tasks;

    event ApplicationSubmit(
        address applicant,
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint32 language,
        uint256 deadline,
        uint256 taskId,
        string src
    );
    event SubtitleCountsUpdate(uint256 taskId, uint256 counts);
    event ApplicationCancel(uint256 taskId);
    event ApplicationRecover(uint256 taskId, uint256 amount, uint256 deadline);
    event ApplicationUpdate(
        uint256 taskId,
        uint256 newAmount,
        uint256 newDeadline
    );
    event ApplicationReset(uint256 taskId, uint256 amount);
    event UserWithdraw(
        address user,
        address platform,
        uint256[] day,
        uint256 all
    );
    event VideoPreExtract(uint256 videoId, uint256 unsettled, uint256 surplus);

    /**
     * @notice 提交制作字幕的申请
     * @param platform 视频所属平台 Platform 区块链地址
     * @param videoId 视频在 Murmes 内的 ID
     * @param strategy 结算策略 ID
     * @param amount 支付金额/比例
     * @param language 申请所需要语言的 ID
     * @return 在 Murmes 内发出申请的顺位, taskId
     */
    function submitApplication(
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint32 language,
        uint256 deadline,
        string memory source
    ) external returns (uint256) {
        // 若调用者未主动加入 Murmes, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 Zimu 数判断用户是否有权限使用 Murmes 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        require(deadline > block.timestamp, "ER1");
        require(settlementStrategy[strategy].strategy != address(0), "ER6");
        totalTasks++;
        authorityStrategy.isOwnApplyAuthority(
            platform,
            videoId,
            source,
            msg.sender,
            strategy,
            amount
        );
        // 当平台地址为 0, 意味着使用默认一次性结算策略
        if (platform == address(this)) {
            // 一次性结算策略下, 需要用户提前授权主合约额度且只能使用 Zimu 代币支付
            require(
                IZimu(zimuToken).transferFrom(
                    msg.sender,
                    address(this),
                    amount
                ),
                "ER12"
            );
        } else {
            (, , , , , , uint256[] memory tasks_) = IPlatform(platforms)
                .getVideoBaseInfo(videoId);
            // 下面是为了防止重复申请制作同一语言的字幕
            for (uint256 i = 0; i < tasks_.length; i++) {
                uint256 taskId = tasks_[i];
                require(tasks[taskId].language != language, "ER0");
            }
            uint256[] memory newTasks = _sortStrategyPriority(
                tasks_,
                strategy,
                totalTasks
            );
            IPlatform(platforms).updateVideoTasks(videoId, newTasks);
        }
        // 实际上这一部分也应该模块化，但考虑到结算策略应该不会再增加，目前先这样设计
        if (strategy == 2 || strategy == 0) {
            // 更新未结算稳定币数目
            ISettlementStrategy(settlementStrategy[strategy].strategy)
                .updateDebtOrReward(totalTasks, 0, amount, 0);
        }
        // 上面都是对不同支付策略时申请变化的判断，也可以或者说应该模块化设计
        tasks[totalTasks].applicant = msg.sender;
        tasks[totalTasks].videoId = videoId;
        tasks[totalTasks].strategy = strategy;
        tasks[totalTasks].amount = amount;
        tasks[totalTasks].language = language;
        tasks[totalTasks].deadline = deadline;
        tasks[totalTasks].platform = platform;
        tasks[totalTasks].source = source;
        // 奖励措施
        IVT(videoToken).mintStableToken(
            0,
            msg.sender,
            users[msg.sender].reputation
        );
        emit ApplicationSubmit(
            msg.sender,
            platform,
            videoId,
            strategy,
            amount,
            language,
            deadline,
            totalTasks,
            source
        );
        return totalTasks;
    }

    /**
     * @notice 每次为视频新添加申请时，根据结算策略优先度更新 applys 数组（主要是方便结算逻辑的执行）
     * @param arr 已有的申请序列
     * @param spot 新申请的策略
     * @param id 新申请的 id
     * @return 从小到大（策略结算优先级）顺序的申请序列
     */
    function _sortStrategyPriority(
        uint256[] memory arr,
        uint256 spot,
        uint256 id
    ) internal view returns (uint256[] memory) {
        uint256[] memory newArr = new uint256[](arr.length + 1);
        if (newArr.length == 1) {
            newArr[0] = id;
            return newArr;
        }
        uint256 flag;
        for (flag = arr.length - 1; flag > 0; flag--) {
            if (spot >= tasks[arr[flag]].strategy) {
                break;
            }
        }
        for (uint256 i = 0; i < newArr.length; i++) {
            if (i <= flag) {
                newArr[i] = arr[i];
            } else if (i == flag + 1) {
                newArr[i] = id;
            } else {
                newArr[i] = arr[i - 1];
            }
        }
        return newArr;
    }

    /**
     * @notice 获得特定申请下所有已上传字幕的指纹, 暂定为 Simhash
     * @param taskId 申请在 Murmes 内的顺位 ID
     * @return 该申请下所有已上传字幕的 fingerprint
     */
    function _getHistoryFingerprint(uint256 taskId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory history = new uint256[](
            tasks[taskId].subtitles.length
        );
        for (uint256 i = 0; i < tasks[taskId].subtitles.length; i++) {
            history[i] = IST(subtitleToken).getSTFingerprint(
                tasks[taskId].subtitles[i]
            );
        }
        return history;
    }

    /**
     * @notice 上传制作的字幕
     * @param taskId 字幕所属申请在 Murmes 内的顺位 ID
     * @param cid 字幕存储在 IPFS 获得的 CID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹值, 暂定为 Simhash
     * @return 字幕 ST ID
     */
    function uploadSubtitle(
        uint256 taskId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256) {
        // 无法为已被确认的申请上传字幕, 防止资金和制作力浪费
        require(tasks[taskId].adopted == 0, "ER3");
        // 期望截至日期前没有字幕上传则申请被冻结
        if (tasks[taskId].subtitles.length == 0) {
            require(block.timestamp <= tasks[taskId].deadline, "ER3-2");
        }
        // 确保字幕的语言与申请所需的语言一致
        require(languageId == tasks[taskId].language, "ER9");
        // 若调用者未主动加入 Murmes, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 Zimu 数判断用户是否有权限使用 Murmes 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        // 通过申请者自设的对字幕制作者的要求
        address guard = users[tasks[taskId].applicant].guard;
        if (guard != address(0)) {
            require(
                IGuard(guard).check(
                    msg.sender,
                    users[msg.sender].reputation,
                    users[msg.sender].deposit,
                    languageId
                ),
                "ER5-2"
            );
        }
        // 字幕相似度检测
        if (
            address(detectionStrategy) != address(0) &&
            tasks[taskId].subtitles.length > 0
        ) {
            uint256[] memory history = _getHistoryFingerprint(taskId);
            require(
                detectionStrategy.beforeDetection(fingerprint, history),
                "ER10"
            );
        }
        // ERC721 Token 生成
        uint256 subtitleId = _createST(
            msg.sender,
            taskId,
            cid,
            languageId,
            fingerprint
        );
        tasks[taskId].subtitles.push(subtitleId);
        return subtitleId;
    }

    /**
     * @notice 由平台 Platform 更新其旗下视频中被确认字幕的使用量，目前只对于分成结算有用
     * @param taskId 相应的申请 ID
     * @param counts 新增使用量
     */
    function updateUsageCounts(
        uint256 taskId,
        uint256 counts,
        uint16 rateCountsToProfit
    ) external {
        require(isOperator(msg.sender), "ER5");
        require(tasks[taskId].strategy == 1, "ER1");
        ISettlementStrategy(settlementStrategy[tasks[taskId].strategy].strategy)
            .updateDebtOrReward(
                taskId,
                counts,
                tasks[taskId].amount,
                rateCountsToProfit
            );
        emit SubtitleCountsUpdate(taskId, counts);
    }

    // function updateUsageCounts(uint256[] memory id, uint256[] memory ms)
    //     external
    // {
    //     require(id.length == ms.length, "ER1");
    //     for (uint256 i = 0; i < id.length; i++) {
    //         if (tasks[id[i]].adopted > 0) {
    //             (address platform, , , , , , ) = IPlatform(platforms)
    //                 .getVideoBaseInfo(tasks[id[i]].videoId);
    //             (, , , uint16 rateCountsToProfit, ) = IPlatform(platforms)
    //                 .getPlatformBaseInfo(platform);
    //             require(msg.sender == platform, "ER5");
    //             require(
    //                 tasks[id[i]].strategy != 0 && tasks[id[i]].strategy != 2,
    //                 "ER1-2"
    //             );
    //             ISettlementStrategy(
    //                 settlementStrategy[tasks[id[i]].strategy].strategy
    //             ).updateDebtOrReward(
    //                     id[i],
    //                     ms[i],
    //                     tasks[id[i]].amount,
    //                     rateCountsToProfit
    //                 );
    //         }
    //     }
    //     emit SubtitleCountsUpdate(msg.sender, id, ms);
    // }

    /**
     * @notice 获得特定字幕与审核相关的信息
     * @param subtitleId 字幕 ID
     * @return 同一申请下已上传字幕数, 该字幕获得的支持数, 该字幕获得的反对数, 同一申请下已上传字幕获得支持数的和
     */
    function getSubtitleAuditInfo(uint256 subtitleId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 taskId = subtitleNFT[subtitleId].taskId;
        uint256 uploaded = tasks[taskId].subtitles.length;
        uint256 allSupport;
        for (uint256 i = 0; i < uploaded; i++) {
            uint256 singleSubtitle = tasks[taskId].subtitles[i];
            allSupport += subtitleNFT[singleSubtitle].supporters.length;
        }
        return (
            uploaded,
            subtitleNFT[subtitleId].supporters.length,
            subtitleNFT[subtitleId].dissenters.length,
            allSupport,
            subtitleNFT[subtitleId].stateChangeTime
        );
    }

    /**
     * @notice 批量更新用户信誉度和质押信息, 字幕状态发生变化时被调用
     * @param subtitleId 字幕 ID
     * @param flag 1 表示字幕被采用（奖励）, 2 表示字幕被认定为恶意字幕（惩罚）
     */
    function _updateUsers(uint256 subtitleId, uint8 flag) internal {
        int8 newFlag = 1;
        uint8 reverseFlag = (flag == 1 ? 2 : 1);
        uint8 multiplier = accessStrategy.multiplier();
        // 2 表示字幕被认定为恶意字幕, 对字幕制作者和支持者进行惩罚, 所以标志位为 负
        if (flag == 2) newFlag = -1;
        // 更新字幕制作者信誉度和 Zimu 质押数信息
        {
            (uint256 reputationSpread, uint256 tokenSpread) = accessStrategy
                .spread(
                    users[IST(subtitleToken).ownerOf(subtitleId)].reputation,
                    flag
                );
            _updateUser(
                IST(subtitleToken).ownerOf(subtitleId),
                int256((reputationSpread * multiplier) / 100) * newFlag,
                int256((tokenSpread * multiplier) / 100) * newFlag
            );
        }
        // 更新审核员信息, 支持者和反对者受到的待遇相反
        for (
            uint256 i = 0;
            i < subtitleNFT[subtitleId].supporters.length;
            i++
        ) {
            (uint256 reputationSpread, uint256 tokenSpread) = accessStrategy
                .spread(
                    users[subtitleNFT[subtitleId].supporters[i]].reputation,
                    flag
                );
            _updateUser(
                subtitleNFT[subtitleId].supporters[i],
                int256(reputationSpread) * newFlag,
                int256(tokenSpread) * newFlag
            );
        }
        for (
            uint256 i = 0;
            i < subtitleNFT[subtitleId].dissenters.length;
            i++
        ) {
            (uint256 reputationSpread, uint256 tokenSpread) = accessStrategy
                .spread(
                    users[subtitleNFT[subtitleId].dissenters[i]].reputation,
                    reverseFlag
                );
            _updateUser(
                subtitleNFT[subtitleId].dissenters[i],
                int256(reputationSpread) * newFlag * (-1),
                int256(tokenSpread) * newFlag * (-1)
            );
        }
    }

    /**
     * @notice 评价/审核字幕
     * @param subtitleId 字幕 ST ID
     * @param attitude 态度, 0 表示积极/支持, 1 表示消极/反对
     */
    function evaluateSubtitle(uint256 subtitleId, uint8 attitude) external {
        // 无法为已被确认的申请上传字幕, 防止资金和制作力浪费
        require(tasks[subtitleNFT[subtitleId].taskId].adopted == 0, "ER3");
        // ST 存在
        require(subtitleNFT[subtitleId].stateChangeTime > 0, "ER1");
        // 若调用者未主动加入 Murmes, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 ETH 数判断用户是否有权限使用 Murmes 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        require(accessStrategy.auditable(users[msg.sender].deposit), "ER5-2");
        _evaluateST(subtitleId, attitude, msg.sender);
        // 基于字幕审核信息和审核策略判断字幕状态改变
        (
            uint256 uploaded,
            uint256 support,
            uint256 against,
            uint256 allSupport,
            uint256 uploadTime
        ) = getSubtitleAuditInfo(subtitleId);
        uint8 flag = auditStrategy.auditResult(
            uploaded,
            support,
            against,
            allSupport,
            uploadTime,
            lockUpTime
        );
        if (flag != 0 && subtitleNFT[subtitleId].state == 0) {
            // 改变 ST 状态, 以及利益相关者信誉度和质押 Zimu 信息
            _changeST(subtitleId, flag);
            _updateUsers(subtitleId, flag);
            // 字幕被采用, 更新相应申请的状态
            if (flag == 1) {
                tasks[subtitleNFT[subtitleId].taskId].adopted = subtitleId;
            }
        }
    }

    /**
     * @notice 预结算（视频和字幕）收益, 此处仅适用于结算策略为一次性结算（0）的申请
     * @param taskId 申请 ID
     */
    function preExtract0(uint256 taskId) external {
        require(tasks[taskId].strategy == 0, "ER6");
        _userInitialization(msg.sender, 0);
        (, , , , uint16 rateAuditorDivide) = IPlatform(platforms)
            .getPlatformBaseInfo(address(this));
        ISettlementStrategy(settlementStrategy[0].strategy).settlement(
            taskId,
            address(this),
            IST(subtitleToken).ownerOf(tasks[taskId].adopted),
            0,
            rateAuditorDivide,
            subtitleNFT[tasks[taskId].adopted].supporters
        );
    }

    /**
     * @notice 预结算时, 遍历用到的结算策略
     * @param videoId 视频在 Murmes 内的 ID
     * @param unsettled 未结算稳定币数
     * @return 本次预结算支付字幕制作费用后剩余的稳定币数目
     */
    function _ergodic(uint256 videoId, uint256 unsettled)
        internal
        returns (uint256)
    {
        // 结算策略 strategy 拥有优先度, 根据id（小的优先级高）划分
        (address platform, , , , , , uint256[] memory tasks_) = IPlatform(
            platforms
        ).getVideoBaseInfo(videoId);
        (, , , , uint16 rateAuditorDivide) = IPlatform(platforms)
            .getPlatformBaseInfo(platform);
        for (uint256 i = 0; i < tasks_.length; i++) {
            uint256 taskId = tasks_[i];
            if (
                tasks[taskId].strategy != 0 &&
                tasks[taskId].adopted > 0 &&
                unsettled > 0
            ) {
                uint256 subtitleGet = ISettlementStrategy(
                    settlementStrategy[tasks[taskId].strategy].strategy
                ).settlement(
                        taskId,
                        platform,
                        IST(subtitleToken).ownerOf(tasks[taskId].adopted),
                        unsettled,
                        rateAuditorDivide,
                        subtitleNFT[tasks[taskId].adopted].supporters
                    );
                unsettled -= subtitleGet;
            }
        }
        return unsettled;
    }

    /**
     * @notice 预结算（视频和字幕）收益, 仍需优化, 实现真正的模块化
     * @param videoId 视频在 Murmes 内的 ID
     * @return 本次结算稳定币数目
     */
    function preExtractOther(uint256 videoId) external returns (uint256) {
        (
            address platform,
            ,
            ,
            address creator,
            ,
            uint256 unsettled,

        ) = IPlatform(platforms).getVideoBaseInfo(videoId);
        require(unsettled > 0, "ER11");
        _userInitialization(msg.sender, 0);
        // 获得相应的代币计价
        (, , uint256 platformId, uint16 rateCountsToProfit, ) = IPlatform(
            platforms
        ).getPlatformBaseInfo(platform);
        uint256 unsettled_ = (rateCountsToProfit * unsettled * (10**6)) /
            RATE_BASE;
        uint256 surplus = _ergodic(videoId, unsettled_);
        // 若支付完字幕制作费用后仍有剩余, 则直接将收益以稳定币的形式发送给视频创作者
        if (surplus > 0) {
            IVT(videoToken).mintStableToken(platformId, creator, surplus);
        }
        IPlatform(platforms).updateVideoUnsettled(
            videoId,
            int256(unsettled) * -1
        );
        emit VideoPreExtract(videoId, unsettled, surplus);
        return unsettled;
    }

    /**
     * @notice 预结算（字幕制作者）收益, "预" 指的是结算后不会直接得到稳定币, 经过锁定期（审核期）后才能提取
     * @param platform 所属平台 Platform 区块链地址
     * @param to 收益接收方
     * @param amount 新增数目
     */
    function preDivide(
        address platform,
        address to,
        uint256 amount
    ) external auth {
        _preDivide(platform, to, amount);
    }

    /**
     * @notice 为批量用户（字幕支持者）预结算收益, "预" 指的是结算后不会直接得到稳定币, 经过锁定期（审核期）后才能提取
     * @param platform 所属平台 Platform 区块链地址
     * @param to 收益接收方
     * @param amount 新增数目
     */
    function preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) external auth {
        _preDivideBatch(platform, to, amount);
    }

    /**
     * @notice 提取经过锁定期的收益
     * @param platform 要提取的平台 Platform 的区块链地址
     * @param day 要提取 天 的集合
     * @return 本次总共提取的（由相应平台背书的）稳定币数
     */
    function withdraw(address platform, uint256[] memory day)
        external
        returns (uint256)
    {
        uint256 all = 0;
        for (uint256 i = 0; i < day.length; i++) {
            if (
                users[msg.sender].lock[platform][day[i]] > 0 &&
                block.timestamp >= day[i] + lockUpTime
            ) {
                all += users[msg.sender].lock[platform][day[i]];
                users[msg.sender].lock[platform][day[i]] = 0;
            }
        }
        if (all > 0) {
            (, , uint256 platformId, , ) = IPlatform(platforms)
                .getPlatformBaseInfo(platform);
            if (fee > 0) {
                uint256 thisFee = (all * fee) / BASE_FEE_RATE;
                all -= thisFee;
                if (platform != address(this)) {
                    IVT(videoToken).mintStableToken(platformId, vault, thisFee);
                } else {
                    require(
                        IZimu(zimuToken).transferFrom(
                            address(this),
                            vault,
                            thisFee
                        ),
                        "ER12"
                    );
                }
                IVault(vault).addFee(platformId, thisFee);
            }
            if (platform != address(this)) {
                IVT(videoToken).mintStableToken(platformId, msg.sender, all);
            } else {
                require(IZimu(zimuToken).transfer(msg.sender, all), "ER12");
            }
        }
        emit UserWithdraw(msg.sender, platform, day, all);
        return all;
    }

    /**
     * @notice 取消申请（仅支持一次性结算策略, 其它的自动冻结）
     * @param taskId 申请 ID
     */
    function cancel(uint256 taskId) external {
        require(msg.sender == tasks[taskId].applicant, "ER5");
        require(
            tasks[taskId].adopted == 0 &&
                tasks[taskId].subtitles.length == 0 &&
                tasks[taskId].deadline <= block.timestamp,
            "ER5-2"
        );
        tasks[taskId].deadline = 0;
        if (tasks[taskId].strategy == 0) {
            require(
                IZimu(zimuToken).transferFrom(
                    address(this),
                    msg.sender,
                    tasks[taskId].amount
                ),
                "ER12"
            );
        }
        emit ApplicationCancel(taskId);
    }

    /**
     * @notice 更新（增加）申请中的额度和（延长）到期时间
     * @param taskId 申请顺位 ID
     * @param plusAmount 增加支付额度
     * @param plusTime 延长到期时间
     */
    function updateApplication(
        uint256 taskId,
        uint256 plusAmount,
        uint256 plusTime
    ) public {
        require(msg.sender == tasks[taskId].applicant, "ER5");
        require(tasks[taskId].adopted == 0, "ER6");
        if (tasks[taskId].deadline <= block.timestamp) {
            emit ApplicationRecover(taskId, plusAmount, plusTime);
        }
        if (tasks[taskId].deadline == 0) {
            tasks[taskId].amount = plusAmount;
            tasks[taskId].deadline = plusTime;
            require(plusTime > block.timestamp + 1 days, "ER1");
        } else {
            tasks[taskId].amount += plusAmount;
            tasks[taskId].deadline += plusTime;
        }
        if (tasks[taskId].strategy == 0) {
            require(
                IZimu(zimuToken).transferFrom(
                    msg.sender,
                    address(this),
                    plusAmount
                ),
                "ER12"
            );
        }
        emit ApplicationUpdate(
            taskId,
            tasks[taskId].amount,
            tasks[taskId].deadline
        );
    }

    /**
     * @notice 该功能服务于后续的仲裁法庭，取消被确认的恶意字幕，相当于重新发出申请
     * @param taskId 被重置的申请 ID
     * @param amount 恢复的代币奖励数量（注意这里以代币计价）
     */
    function resetApplication(uint256 taskId, uint256 amount) public auth {
        delete tasks[taskId].adopted;
        tasks[taskId].deadline = block.timestamp + lockUpTime;
        ISettlementStrategy(settlementStrategy[tasks[taskId].strategy].strategy)
            .resetSettlement(taskId, amount);
        emit ApplicationReset(taskId, amount);
    }

    /**
     * @notice 根据申请 ID 获得其所属的平台
     * @param taskId 申请/任务 ID
     * @return 申请所属的平台
     */
    function getPlatformByTaskId(uint256 taskId)
        external
        view
        returns (address)
    {
        require(tasks[taskId].applicant != address(0), "ER1");
        return tasks[taskId].platform;
    }

    function getTaskPaymentStrategyAndSubtitles(uint256 taskId)
        public
        view
        returns (
            uint8,
            uint256,
            uint256[] memory
        )
    {
        return (
            tasks[taskId].strategy,
            tasks[taskId].amount,
            tasks[taskId].subtitles
        );
    }
}
