/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-07 17:56:09
 * @Description: 基于区块链的代币化字幕众包系统 - Murmes
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./base/TaskManager.sol";
import "./interfaces/IGuard.sol";
import "./interfaces/IPlatform.sol";
import "./interfaces/IAccessModule.sol";
import "./common/token/ERC20/IERC20.sol";
import "./interfaces/IPlatformToken.sol";
import "./interfaces/IDetectionModule.sol";
import "./interfaces/ISettlementModule.sol";

contract Murmes is TaskManager {
    constructor(address dao, address mutliSig) {
        _setOwner(dao);
        _setMutliSig(mutliSig);
        requiresNoteById.push("None");
    }

    function postTask(DataTypes.PostTaskData calldata vars)
        external
        returns (uint256)
    {
        _validatePostTaskData(
            vars.currency,
            vars.auditModule,
            vars.detectionModule
        );
        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);
        require(
            vars.deadline > block.timestamp &&
                vars.requireId < requiresNoteById.length,
            "11"
        );

        totalTasks++;
        uint256 orderId; //
        // uint256 orderId = authorityStrategy.isOwnApplyAuthority(
        //     platform,
        //     videoId,
        //     source,
        //     msg.sender,
        //     strategy,
        //     amount
        // );
        if (vars.platform == address(this)) {
            assert(vars.settlement == DataTypes.SettlementType.ONETIME);
            require(
                IERC20(vars.currency).transferFrom(
                    msg.sender,
                    address(this),
                    vars.amount
                ),
                "112"
            );
        } else {
            address platforms = IComponentGlobal(componentGlobal).platforms();
            uint256[] memory _tasks = IPlatform(platforms).getBoxTasks(orderId);
            for (uint256 i = 0; i < _tasks.length; i++) {
                require(tasks[_tasks[i]].requires != vars.requireId, "10");
            }
            uint256[] memory newTasks = _sortSettlementPriority(
                _tasks,
                vars.settlement,
                totalTasks
            );
            IPlatform(platforms).updateBoxTasks(orderId, newTasks);
        }

        if (vars.settlement != DataTypes.SettlementType.DIVIDEND) {
            address settlementModule = IModuleGlobal(moduleGlobal)
                .getSettlementModuleAddress(vars.settlement);
            ISettlementModule(settlementModule).updateDebtOrReward(
                totalTasks,
                0,
                vars.amount,
                0
            );
        }

        tasks[totalTasks].applicant = msg.sender;
        tasks[totalTasks].platform = vars.platform;
        tasks[totalTasks].sourceId = orderId;
        tasks[totalTasks].requireId = vars.requireId;
        tasks[totalTasks].source = vars.source;
        tasks[totalTasks].settlement = vars.settlement;
        tasks[totalTasks].amount = vars.amount;
        tasks[totalTasks].currency = vars.currency;
        tasks[totalTasks].auditModule = vars.auditModule;
        tasks[totalTasks].detectionModule = vars.detectionModule;
        tasks[totalTasks].deadline = vars.deadline;

        _rewardMurmesToken(msg.sender);
        return totalTasks;
    }

    // function _getHistoryFingerprint(uint256 taskId)
    //     internal
    //     view
    //     returns (uint256[] memory)
    // {
    //     uint256[] memory history = new uint256[](tasks[taskId].items.length);
    //     for (uint256 i = 0; i < tasks[taskId].items.length; i++) {
    //         history[i] = IST(subtitleToken).getSTFingerprint(
    //             tasks[taskId].items[i]
    //         );
    //     }
    //     return history;
    // }

    function submitItem(DataTypes.SubmitItemData vars)
        external
        returns (uint256)
    {
        require(tasks[vars.taskId].adopted == 0, "43");
        if (tasks[vars.taskId].items.length == 0) {
            require(block.timestamp <= tasks[vars.taskId].deadline, "432");
        }
        require(vars.requireId == tasks[vars.taskId].requireId, "49");

        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);
        _validateSubmitItemData(vars.taskId, vars.fingerprint);

        address guard = users[tasks[vars.taskId].applicant].guard;
        if (guard != address(0)) {
            require(
                IGuard(guard).checkForSubmit(
                    msg.sender,
                    users[msg.sender].reputation,
                    users[msg.sender].deposit,
                    vars.requireId
                )
            );
        }

        uint256 itemId = _createItem(
            msg.sender,
            vars.taskId,
            vars.cid,
            vars.requireId,
            vars.fingerprint
        );
        tasks[vars.taskId].subtitles.push(itemId);
        return itemId;
    }

    function auditItem(uint256 itemId, DataTypes.AuditAttitude attitude)
        external
    {
        uint256 taskId = itemsNFT[itemId].taskId;
        require(tasks[taskId].adopted == 0, "83");
        require(itemsNFT[itemId].stateChangeTime > 0, "81");

        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);

        if (tasks[taskId].auditModule != address(0)) {
            require(accessStrategy.auditable(users[msg.sender].deposit), "852");
        }

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

    function updateUsageCounts(
        uint256 taskId,
        uint256 counts,
        uint16 rateCountsToProfit
    ) external {
        require(isOperator(msg.sender), "55");
        require(tasks[taskId].strategy == 1, "51");
        ISettlementStrategy(settlementStrategy[tasks[taskId].strategy].strategy)
            .updateDebtOrReward(
                taskId,
                counts,
                tasks[taskId].amount,
                rateCountsToProfit
            );
    }

    /**
     * @notice 获得特定字幕与审核相关的信息
     * @param subtitleId 字幕 ID
     * @return 同一申请下已上传字幕数, 该字幕获得的支持数, 该字幕获得的反对数, 同一申请下已上传字幕获得支持数的和
     * label M6
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
     * label M7
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
     * @notice 预结算（视频和字幕）收益, 此处仅适用于结算策略为一次性结算（0）的申请
     * @param taskId 申请 ID
     * label M9
     */
    function preExtract0(uint256 taskId) external {
        require(tasks[taskId].strategy == 0, "96");
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
     * label M10
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
     * label M11
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
        require(unsettled > 0, "1111");
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
     * label M12
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
     * label M13
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
     * label M14
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
            uint256 fee = IVault(vault).fee();
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
                        "1412"
                    );
                }
                IVault(vault).addFee(platformId, thisFee);
            }
            if (platform != address(this)) {
                IVT(videoToken).mintStableToken(platformId, msg.sender, all);
            } else {
                require(IZimu(zimuToken).transfer(msg.sender, all), "14122");
            }
        }
        emit UserWithdraw(msg.sender, platform, day, all);
        return all;
    }

    function _validatePostTaskData(
        address currency,
        address audit,
        address detection
    ) internal {
        require(
            IModuleGlobal(moduleGlobal).isPostTaskModuleValid(
                currency,
                audit,
                detection
            )
        );
    }

    function _validateCaller(address caller) internal {
        address access = IComponentGlobal(componentGlobal).access();
        require(
            IAccessModule(access).access(
                users[msg.sender].reputation,
                users[msg.sender].deposit
            )
        );
    }

    function _validateSubmitItemData(uint256 taskId, uint256 fingerprint)
        internal
    {
        if (
            tasks[taskId].detectionModule != address(0) &&
            tasks[taskId].items.length > 0
        ) {
            // uint256[] memory history = _getHistoryFingerprint(taskId);
            address detection = tasks[taskId].detectionModule;
            require(
                ISettlementModule(detection).beforeDetection(
                    taskId,
                    fingerprint
                ),
                "410"
            );
        }
    }

    function _sortSettlementPriority(
        uint256[] memory arr,
        DataTypes.SettlementType spot,
        uint256 id
    ) internal view returns (uint256[] memory) {
        uint256[] memory newArr = new uint256[](arr.length + 1);
        if (newArr.length == 1) {
            newArr[0] = id;
            return newArr;
        }
        uint256 flag;
        for (flag = arr.length - 1; flag > 0; flag--) {
            if (uint8(spot) >= uint8(tasks[arr[flag]].settlement)) {
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

    function _rewardMurmesToken(address to) internal {
        address platformToken = IComponentGlobal(componentGlobal)
            .platformToken();
        IPlatformToken(platformToken).mintPlatformToken(
            0,
            to,
            users[msg.sender].reputation
        );
    }

    /**
     * @notice 根据申请 ID 获得其所属的平台
     * @param taskId 申请/任务 ID
     * @return 申请所属的平台
     * label M18
     */
    function getPlatformByTaskId(uint256 taskId)
        external
        view
        returns (address)
    {
        require(tasks[taskId].applicant != address(0), "181");
        return tasks[taskId].platform;
    }

    // label M19
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
