/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-07 17:56:09
 * @Description: 基于区块链的代币化字幕众包系统
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/ISettlementStrategy.sol";
import "./base/StrategyManager.sol";
import "./base/VideoManager.sol";

contract SubtitleSystem is StrategyManager, VideoManager {
    /**
     * @notice TSCS 内已经发出的申请总数
     */
    uint256 public totalApplyNumber;

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
        uint16 language;
        uint256[] subtitles;
        uint256 adopted;
        uint256 deadline;
    }

    constructor(address owner) {
        _setOwner(owner);
        // 当结算类型为一次性结算时, 默认字幕支持者分成 1/100
        platforms[address(0)].rateAuditorDivide = 655;
        platforms[address(0)].name = "Default";
        platforms[address(0)].symbol = "Default";
        languageTypes.push("Default");
    }

    /**
     * @notice applyId 与 Application 的映射, 从 1 开始（发出申请的顺位）
     */
    mapping(uint256 => Application) public totalApplys;

    event ApplicationSubmit(
        address applicant,
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint16 language,
        uint256 deadline,
        uint256 applyId,
        string src
    );
    event SubtitleCountsUpdate(
        address platform,
        uint256[] subtitleId,
        uint256[] counts
    );
    // event ApplicationCancel(uint256 applyId);
    event ApplicationRecover(uint256 applyId, uint256 amount, uint256 deadline);
    event ApplicationUpdate(
        uint256 applyId,
        uint256 newAmount,
        uint256 newDeadline
    );
    event ApplicationReset(uint256 applyId, uint256 amount);
    event UserWithdraw(
        address user,
        address platform,
        uint256[] day,
        uint256 all
    );
    event VideoPreExtract(uint256 videoId, uint256 unsettled, uint256 surplus);

    /**
     * @notice 由平台 Platform 注册视频, 此后该视频支持链上结算（意味着更多结算策略的支持）
     * @param id 视频在 Platform 内部的 ID
     * @param symbol 视频的 symbol
     * @param creator 视频创作者区块链地址
     * @return 视频在 TSCS 内的 ID
     */
    function createVideo(
        uint256 id,
        string memory symbol,
        address creator
    ) external returns (uint256) {
        require(platforms[msg.sender].rateCountsToProfit > 0, "ER1");
        uint256 videoId = _createVideo(msg.sender, id, symbol, creator);
        return videoId;
    }

    /**
     * @notice 提交制作字幕的申请
     * @param platform 视频所属平台 Platform 区块链地址
     * @param videoId 视频在 TSCS 内的 ID
     * @param strategy 结算策略 ID
     * @param amount 支付金额/比例
     * @param language 申请所需要语言的 ID
     * @return 在 TSCS 内发出申请的顺位, applyId
     */
    function submitApplication(
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint16 language,
        uint256 deadline,
        string memory source
    ) external returns (uint256) {
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 Zimu 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        require(deadline > block.timestamp, "ER1");
        require(settlementStrategy[strategy].strategy != address(0), "ER6");
        totalApplyNumber++;
        // 当平台地址为 0, 意味着使用默认一次性结算策略
        if (platform == address(0)) {
            require(strategy == 0, "ER7");
            require(bytes(source).length > 0, "ER1-7");
            // 一次性结算策略下, 需要用户提前授权主合约额度且只能使用 Zimu 代币支付
            IZimu(zimuToken).transferFrom(msg.sender, address(this), amount);
        } else {
            // 当结算策略非一次性时, 与视频收益相关, 需要由视频创作者主动提起
            require(videos[videoId].creator == msg.sender, "ER5");
            // 下面是为了防止重复申请制作同一语言的字幕
            for (uint256 i; i < videos[videoId].applys.length; i++) {
                uint256 applyId = videos[videoId].applys[i];
                require(totalApplys[applyId].language != language, "ER0");
            }
            uint256[] memory newApplyArr = _sortStrategyPriority(
                videos[videoId].applys,
                strategy,
                totalApplyNumber
            );
            videos[videoId].applys = newApplyArr;
        }
        if (strategy == 2 || strategy == 0) {
            // 更新未结算稳定币数目
            ISettlementStrategy(settlementStrategy[strategy].strategy)
                .updateDebtOrReward(totalApplyNumber, 0, amount, 0);
        }
        // 上面都是对不同支付策略时申请变化的判断，也可以或者说应该模块化设计
        totalApplys[totalApplyNumber].applicant = msg.sender;
        totalApplys[totalApplyNumber].videoId = videoId;
        totalApplys[totalApplyNumber].strategy = strategy;
        totalApplys[totalApplyNumber].amount = amount;
        totalApplys[totalApplyNumber].language = language;
        totalApplys[totalApplyNumber].deadline = deadline;
        totalApplys[totalApplyNumber].platform = platform;
        totalApplys[totalApplyNumber].source = source;
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
            totalApplyNumber,
            source
        );
        return totalApplyNumber;
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
            if (spot >= totalApplys[arr[flag]].strategy) {
                break;
            }
        }
        for (uint256 i; i < newArr.length; i++) {
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
     * @param applyId 申请在 TSCS 内的顺位 ID
     * @return 该申请下所有已上传字幕的 fingerprint
     */
    function _getHistoryFingerprint(uint256 applyId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory history = new uint256[](
            totalApplys[applyId].subtitles.length
        );
        for (uint256 i = 0; i < totalApplys[applyId].subtitles.length; i++) {
            history[i] = IST(subtitleToken).getSTFingerprint(
                totalApplys[applyId].subtitles[i]
            );
        }
        return history;
    }

    /**
     * @notice 上传制作的字幕
     * @param applyId 字幕所属申请在 TSCS 内的顺位 ID
     * @param cid 字幕存储在 IPFS 获得的 CID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹值, 暂定为 Simhash
     * @return 字幕 ST ID
     */
    function uploadSubtitle(
        uint256 applyId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256) {
        // 无法为已被确认的申请上传字幕, 防止资金和制作力浪费
        require(totalApplys[applyId].adopted == 0, "ER3");
        // 期望截至日期前没有字幕上传则申请被冻结
        if (totalApplys[applyId].subtitles.length == 0) {
            require(block.timestamp <= totalApplys[applyId].deadline, "ER3");
        }
        // 确保字幕的语言与申请所需的语言一致
        require(languageId == totalApplys[applyId].language, "ER9");
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 Zimu 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
        uint256[] memory history = _getHistoryFingerprint(applyId);
        // 字幕相似度检测
        if (address(detectionStrategy) != address(0)) {
            require(
                detectionStrategy.beforeDetection(fingerprint, history),
                "ER10"
            );
        }
        // ERC721 Token 生成
        uint256 subtitleId = _createST(
            msg.sender,
            applyId,
            cid,
            languageId,
            fingerprint
        );
        totalApplys[applyId].subtitles.push(subtitleId);
        return subtitleId;
    }

    /**
     * @notice 由平台 Platform 更新其旗下视频中被确认字幕的使用量，目前只对于分成结算有用
     * @param id 相应的申请 ID
     * @param ss 新增使用量
     */
    function updateUsageCounts(uint256[] memory id, uint256[] memory ss)
        external
    {
        require(id.length == ss.length, "ER1");
        for (uint256 i = 0; i < id.length; i++) {
            if (totalApplys[id[i]].adopted > 0) {
                address platform = videos[totalApplys[id[i]].videoId].platform;
                require(msg.sender == platform, "ER5");
                require(
                    totalApplys[id[i]].strategy != 0 &&
                        totalApplys[id[i]].strategy != 2,
                    "ER1"
                );
                ISettlementStrategy(
                    settlementStrategy[totalApplys[id[i]].strategy].strategy
                ).updateDebtOrReward(
                        id[i],
                        ss[i],
                        totalApplys[id[i]].amount,
                        platforms[platform].rateCountsToProfit
                    );
            }
        }
        emit SubtitleCountsUpdate(msg.sender, id, ss);
    }

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
        uint256 applyId = subtitleNFT[subtitleId].applyId;
        uint256 uploaded = totalApplys[applyId].subtitles.length;
        uint256 allSupport;
        for (uint256 i = 0; i < uploaded; i++) {
            uint256 singleSubtitle = totalApplys[applyId].subtitles[i];
            allSupport += subtitleNFT[singleSubtitle].supporters.length;
        }
        return (
            uploaded,
            subtitleNFT[subtitleId].supporters.length,
            subtitleNFT[subtitleId].dissenter.length,
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
        for (uint256 i = 0; i < subtitleNFT[subtitleId].dissenter.length; i++) {
            (uint256 reputationSpread, uint256 tokenSpread) = accessStrategy
                .spread(
                    users[subtitleNFT[subtitleId].dissenter[i]].reputation,
                    flag
                );
            _updateUser(
                subtitleNFT[subtitleId].dissenter[i],
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
        require(
            totalApplys[subtitleNFT[subtitleId].applyId].adopted == 0,
            "ER3"
        );
        if (attitude == 1) {
            require(
                users[msg.sender].deposit ==
                    int256(accessStrategy.minDeposit()),
                "ER5"
            );
        }
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 ETH 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            ),
            "ER5"
        );
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
                totalApplys[subtitleNFT[subtitleId].applyId]
                    .adopted = subtitleId;
            }
        }
    }

    /**
     * @notice 预结算（视频和字幕）收益, 此处仅适用于结算策略为一次性结算（0）的申请
     * @param applyId 申请 ID
     */
    function preExtract0(uint256 applyId) external {
        require(totalApplys[applyId].strategy == 0, "ER6");
        address platform = videos[totalApplys[applyId].videoId].platform;
        ISettlementStrategy(settlementStrategy[0].strategy).settlement(
            applyId,
            platform,
            IST(subtitleToken).ownerOf(totalApplys[applyId].adopted),
            0,
            platforms[platform].rateAuditorDivide,
            subtitleNFT[totalApplys[applyId].adopted].supporters
        );
    }

    /**
     * @notice 预结算时, 遍历用到的结算策略
     * @param videoId 视频在 TSCS 内的 ID
     * @param unsettled 未结算稳定币数
     * @return 本次预结算支付字幕制作费用后剩余的稳定币数目
     */
    function _ergodic(uint256 videoId, uint256 unsettled)
        internal
        returns (uint256)
    {
        // 结算策略 strategy 拥有优先度, 根据id（小的优先级高）划分
        for (uint256 i = 0; i < videos[videoId].applys.length; i++) {
            uint256 applyId = videos[videoId].applys[i];
            if (
                totalApplys[applyId].strategy != 0 &&
                totalApplys[applyId].adopted > 0 &&
                unsettled > 0
            ) {
                address platform = videos[videoId].platform;
                uint256 subtitleGet = ISettlementStrategy(
                    settlementStrategy[totalApplys[applyId].strategy].strategy
                ).settlement(
                        applyId,
                        platform,
                        IST(subtitleToken).ownerOf(
                            totalApplys[applyId].adopted
                        ),
                        unsettled,
                        platforms[platform].rateAuditorDivide,
                        subtitleNFT[totalApplys[applyId].adopted].supporters
                    );
                unsettled -= subtitleGet;
            }
        }
        return unsettled;
    }

    /**
     * @notice 预结算（视频和字幕）收益, 仍需优化, 实现真正的模块化
     * @param videoId 视频在 TSCS 内的 ID
     * @return 本次结算稳定币数目
     */
    function preExtractOther(uint256 videoId) external returns (uint256) {
        require(videos[videoId].unsettled > 0, "ER11");
        // 获得相应的代币计价
        uint256 unsettled = (platforms[videos[videoId].platform]
            .rateCountsToProfit *
            videos[videoId].unsettled *
            (10**6)) / RATE_BASE;
        uint256 surplus = _ergodic(videoId, unsettled);
        // 若支付完字幕制作费用后仍有剩余, 则直接将收益以稳定币的形式发送给视频创作者
        if (surplus > 0) {
            IVT(videoToken).mintStableToken(
                platforms[videos[videoId].platform].platformId,
                videos[videoId].creator,
                surplus
            );
        }

        videos[videoId].unsettled = 0;
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
        uint256 all;
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
            if (fee > 0) {
                uint256 thisFee = (all * fee) / BASE_FEE_RATE;
                all -= thisFee;
                if (platform != address(0)) {
                    IVT(videoToken).mintStableToken(
                        platforms[platform].platformId,
                        vault,
                        thisFee
                    );
                } else {
                    IZimu(zimuToken).transferFrom(
                        address(this),
                        vault,
                        thisFee
                    );
                }
                IVault(vault).addFee(platforms[platform].platformId, thisFee);
            }
            if (platform != address(0)) {
                IVT(videoToken).mintStableToken(
                    platforms[platform].platformId,
                    msg.sender,
                    all
                );
            } else {
                IZimu(zimuToken).transfer(msg.sender, all);
            }
        }
        emit UserWithdraw(msg.sender, platform, day, all);
        return all;
    }

    /**
     * @notice 取消申请（仅支持一次性结算策略, 其它的自动冻结）
     * @param applyId 申请 ID
     */
    // function cancel(uint256 applyId) external {
    //     require(msg.sender == totalApplys[applyId].applicant, "ER5");
    //     require(
    //         totalApplys[applyId].adopted == 0 &&
    //             totalApplys[applyId].subtitles.length == 0 &&
    //             totalApplys[applyId].deadline <= block.timestamp,
    //         "ER1-5"
    //     );
    //     require(totalApplys[applyId].strategy == 0, "ER6");
    //     totalApplys[applyId].deadline = 0;
    //     uint256 platformId = platforms[
    //         videos[totalApplys[applyId].videoId].platform
    //     ].platformId;
    //     IVT(videoToken).mintStableToken(
    //         platformId,
    //         msg.sender,
    //         totalApplys[applyId].amount
    //     );
    //     emit ApplicationCancel(applyId);
    // }

    /**
     * @notice 恢复申请（一次性结算策略的申请无法恢复, 必须重新发起）
     * @param applyId 申请 ID
     * @param amount 新的支付金额/比例
     * @param deadline 新的截至期限
     */
    function recover(
        uint256 applyId,
        uint256 amount,
        uint256 deadline
    ) external {
        require(msg.sender == totalApplys[applyId].applicant, "ER5");
        require(
            totalApplys[applyId].adopted == 0 &&
                totalApplys[applyId].subtitles.length == 0 &&
                totalApplys[applyId].deadline <= block.timestamp,
            "ER1-5"
        );
        require(totalApplys[applyId].strategy != 0, "ER6");
        require(deadline > block.timestamp, "ER1");
        totalApplys[applyId].deadline = deadline;
        totalApplys[applyId].amount = amount;
        emit ApplicationRecover(applyId, amount, deadline);
    }

    /**
     * @notice 更新（增加）申请中的额度和（延长）到期时间
     * @param applyId 申请顺位 ID
     * @param plusAmount 增加支付额度
     * @param plusTime 延长到期时间
     */
    function updateApplication(
        uint256 applyId,
        uint256 plusAmount,
        uint256 plusTime
    ) public {
        require(msg.sender == totalApplys[applyId].applicant, "ER5");
        require(totalApplys[applyId].adopted == 0, "ER6");
        totalApplys[applyId].amount += plusAmount;
        totalApplys[applyId].deadline += plusTime;
        emit ApplicationUpdate(
            applyId,
            totalApplys[applyId].amount,
            totalApplys[applyId].deadline
        );
    }

    /**
     * @notice 该功能服务于后续的仲裁法庭，取消被确认的恶意字幕，相当于重新发出申请
     * @param applyId 被重置的申请 ID
     * @param amount 恢复的代币奖励数量（注意这里以代币计价）
     */
    function resetApplication(uint256 applyId, uint256 amount) public auth {
        _changeST(totalApplys[applyId].adopted, 2);
        delete totalApplys[applyId].adopted;
        totalApplys[applyId].deadline = block.timestamp + 7 days;
        ISettlementStrategy(
            settlementStrategy[totalApplys[applyId].strategy].strategy
        ).resetSettlement(applyId, amount);
        emit ApplicationReset(applyId, amount);
    }
}
