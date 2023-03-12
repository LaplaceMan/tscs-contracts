/**
 * @Author: LaplaceMan
 * @Description: 基于区块链的众包协议 - Murmes
 * @Copyright (c) 2023 by LaplaceMan heichenclone@gmail.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./base/TaskManager.sol";
import "./interfaces/IGuard.sol";
import "./interfaces/IPlatforms.sol";
import "./interfaces/IAuditModule.sol";
import "./interfaces/IAccessModule.sol";
import "./interfaces/IPlatformToken.sol";
import "./interfaces/IDetectionModule.sol";

contract Murmes is TaskManager {
    constructor(address dao, address mutliSig) {
        _setOwner(dao);
        _setMutliSig(mutliSig);
        requiresNoteById.push("None");
    }

    function postTask(
        DataTypes.PostTaskData calldata vars
    ) external returns (uint256) {
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
            uint256[] memory _tasks = IPlatforms(platforms).getBoxTasks(
                orderId
            );
            for (uint256 i = 0; i < _tasks.length; i++) {
                require(tasks[_tasks[i]].requireId != vars.requireId, "10");
            }
            uint256[] memory newTasks = _sortSettlementPriority(
                _tasks,
                vars.settlement,
                totalTasks
            );
            IPlatforms(platforms).updateBoxTasks(orderId, newTasks);
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

    function submitItem(
        DataTypes.ItemMetadata calldata vars
    ) external returns (uint256) {
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

        uint256 itemId = _createItem(msg.sender, vars);
        tasks[vars.taskId].items.push(itemId);
        return itemId;
    }

    function auditItem(
        uint256 itemId,
        DataTypes.AuditAttitude attitude
    ) external {
        uint256 taskId = itemsNFT[itemId].taskId;
        require(tasks[taskId].adopted == 0, "83");
        require(itemsNFT[itemId].stateChangeTime > 0, "81");

        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);
        {
            address access = IComponentGlobal(componentGlobal).access();
            require(
                IAccessModule(access).auditable(users[msg.sender].deposit),
                "852"
            );
        }
        _evaluateItem(itemId, attitude, msg.sender);
        // 基于字幕审核信息和审核策略判断字幕状态改变
        (
            uint256 uploaded,
            uint256 support,
            uint256 against,
            uint256 allSupport,
            uint256 uploadTime
        ) = getItemAuditInfo(itemId);
        DataTypes.ItemState flag = IAuditModule(tasks[taskId].auditModule)
            .auditResult(
                uploaded,
                support,
                against,
                allSupport,
                uploadTime,
                IComponentGlobal(componentGlobal).lockUpTime()
            );
        if (
            flag != DataTypes.ItemState.NORMAL &&
            itemsNFT[itemId].state == DataTypes.ItemState.NORMAL
        ) {
            _changeItemState(itemId, flag);
            _updateUsers(itemId, flag);
            if (flag == DataTypes.ItemState.ADOPTED) {
                tasks[itemsNFT[itemId].taskId].adopted = itemId;
            }
        }
    }

    function updateItemRevenue(
        uint256 taskId,
        uint256 counts,
        uint16 rateCountsToProfit
    ) external {
        require(
            isOperator(msg.sender) || msg.sender == tasks[taskId].platform,
            "55"
        );
        require(
            tasks[taskId].settlement == DataTypes.SettlementType.DIVIDEND,
            "51"
        );
        address thisSettlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(tasks[taskId].settlement);
        ISettlementModule(thisSettlement).updateDebtOrReward(
            taskId,
            counts,
            tasks[taskId].amount,
            rateCountsToProfit
        );
    }

    function preExtractForNormal(uint256 taskId) external {
        require(
            tasks[taskId].settlement == DataTypes.SettlementType.ONETIME,
            "96"
        );
        _userInitialization(msg.sender, 0);
        address platforms = IComponentGlobal(componentGlobal).platforms();
        DataTypes.PlatformStruct memory platformInfo = IPlatforms(platforms)
            .getPlatform(address(this));
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(DataTypes.SettlementType.ONETIME);
        address itemNFT = IComponentGlobal(componentGlobal).itemToken();
        ISettlementModule(settlement).settlement(
            taskId,
            address(this),
            IItemNFT(itemNFT).ownerOf(tasks[taskId].adopted),
            0,
            platformInfo.rateAuditorDivide,
            itemsNFT[tasks[taskId].adopted].supporters
        );
    }

    function preExtractOther(uint256 boxId) external returns (uint256) {
        address platforms = IComponentGlobal(componentGlobal).platforms();
        DataTypes.BoxStruct memory boxInfo = IPlatforms(platforms).getBox(
            boxId
        );
        require(boxInfo.unsettled > 0, "1111");
        DataTypes.PlatformStruct memory platformInfo = IPlatforms(platforms)
            .getPlatform(boxInfo.platform);
        uint256 unsettled = (platformInfo.rateCountsToProfit *
            boxInfo.unsettled *
            (10 ** 6)) / BASE_RATE;
        uint256 surplus = _ergodic(boxId, unsettled);
        address platformToken = IComponentGlobal(componentGlobal)
            .platformToken();
        if (surplus > 0) {
            IPlatformToken(platformToken).mintPlatformToken(
                platformInfo.platformId,
                boxInfo.creator,
                surplus
            );
        }
        IPlatforms(platforms).updateBoxUnsettledRevenue(
            boxId,
            int256(unsettled) * -1
        );
        return unsettled;
    }

    function preDivide(
        address platform,
        address to,
        uint256 amount
    ) external auth {
        _preDivide(platform, to, amount);
    }

    function preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) external auth {
        _preDivideBatch(platform, to, amount);
    }

    function withdraw(
        address platform,
        uint256[] memory day
    ) external returns (uint256) {
        uint256 all = 0;

        for (uint256 i = 0; i < day.length; i++) {
            if (
                users[msg.sender].locks[platform][day[i]] > 0 &&
                block.timestamp >=
                day[i] + IComponentGlobal(componentGlobal).lockUpTime()
            ) {
                all += users[msg.sender].locks[platform][day[i]];
                users[msg.sender].locks[platform][day[i]] = 0;
            }
        }
        if (all > 0) {
            address platforms = IComponentGlobal(componentGlobal).platforms();
            DataTypes.PlatformStruct memory platformInfo = IPlatforms(platforms)
                .getPlatform(platform);
            address vault = IComponentGlobal(componentGlobal).vault();
            uint256 fee = IVault(vault).fee();
            address platformToken = IComponentGlobal(componentGlobal)
                .platformToken();
            if (fee > 0) {
                uint256 thisFee = (all * fee) / BASE_RATE;
                address recipient = IVault(vault).feeRecipient();
                all -= thisFee;
                if (platform != address(this)) {
                    IPlatformToken(platformToken).mintPlatformToken(
                        platformInfo.platformId,
                        recipient,
                        thisFee
                    );
                } else {
                    // 此时，platform为currency
                    require(
                        IERC20(platform).transferFrom(
                            address(this),
                            recipient,
                            thisFee
                        ),
                        "1412"
                    );
                }
            }
            if (platform != address(this)) {
                IPlatformToken(platformToken).mintPlatformToken(
                    platformInfo.platformId,
                    msg.sender,
                    all
                );
            } else {
                require(IERC20(platform).transfer(msg.sender, all), "14122");
            }
        }
        return all;
    }

    function _updateUsers(uint256 itemId, DataTypes.ItemState flag) internal {
        int8 newFlag = 1;
        uint8 reverseFlag = (uint8(flag) == 1 ? 2 : 1);
        address access = IComponentGlobal(componentGlobal).access();
        uint8 multiplier = IAccessModule(access).multiplier();

        if (flag == DataTypes.ItemState.DELETED) newFlag = -1;
        {
            address itemToken = IComponentGlobal(componentGlobal).itemToken();
            (uint256 reputationSpread, uint256 tokenSpread) = IAccessModule(
                access
            ).spread(
                    users[IItemNFT(itemToken).ownerOf(itemId)].reputation,
                    uint8(flag)
                );
            _updateUser(
                IItemNFT(itemToken).ownerOf(itemId),
                int256((reputationSpread * multiplier) / 100) * newFlag,
                int256((tokenSpread * multiplier) / 100) * newFlag
            );
        }

        for (uint256 i = 0; i < itemsNFT[itemId].supporters.length; i++) {
            (uint256 reputationSpread, uint256 tokenSpread) = IAccessModule(
                access
            ).spread(
                    users[itemsNFT[itemId].supporters[i]].reputation,
                    uint8(flag)
                );
            _updateUser(
                itemsNFT[itemId].supporters[i],
                int256(reputationSpread) * newFlag,
                int256(tokenSpread) * newFlag
            );
        }
        for (uint256 i = 0; i < itemsNFT[itemId].opponents.length; i++) {
            (uint256 reputationSpread, uint256 tokenSpread) = IAccessModule(
                access
            ).spread(
                    users[itemsNFT[itemId].opponents[i]].reputation,
                    reverseFlag
                );
            _updateUser(
                itemsNFT[itemId].opponents[i],
                int256(reputationSpread) * newFlag * (-1),
                int256(tokenSpread) * newFlag * (-1)
            );
        }
    }

    function _ergodic(
        uint256 boxId,
        uint256 unsettled
    ) internal returns (uint256) {
        address platforms = IComponentGlobal(componentGlobal).platforms();
        DataTypes.BoxStruct memory boxInfo = IPlatforms(platforms).getBox(
            boxId
        );
        DataTypes.PlatformStruct memory platformInfo = IPlatforms(platforms)
            .getPlatform(boxInfo.platform);
        address itemNFT = IComponentGlobal(componentGlobal).itemToken();
        for (uint256 i = 0; i < boxInfo.tasks.length; i++) {
            uint256 taskId = boxInfo.tasks[i];
            if (
                tasks[taskId].settlement != DataTypes.SettlementType.ONETIME &&
                tasks[taskId].adopted > 0 &&
                unsettled > 0
            ) {
                address settlement = IModuleGlobal(moduleGlobal)
                    .getSettlementModuleAddress(tasks[taskId].settlement);
                uint256 itemGetReward = ISettlementModule(settlement)
                    .settlement(
                        taskId,
                        boxInfo.platform,
                        IItemNFT(itemNFT).ownerOf(tasks[taskId].adopted),
                        unsettled,
                        platformInfo.rateAuditorDivide,
                        itemsNFT[tasks[taskId].adopted].supporters
                    );
                unsettled -= itemGetReward;
            }
        }
        return unsettled;
    }

    function _validatePostTaskData(
        address currency,
        address audit,
        address detection
    ) internal view {
        require(
            IModuleGlobal(moduleGlobal).isPostTaskModuleValid(
                currency,
                audit,
                detection
            )
        );
    }

    function _validateCaller(address caller) internal view {
        address access = IComponentGlobal(componentGlobal).access();
        require(
            IAccessModule(access).access(
                users[caller].reputation,
                users[caller].deposit
            )
        );
    }

    function _validateSubmitItemData(
        uint256 taskId,
        uint256 fingerprint
    ) internal view {
        if (
            tasks[taskId].detectionModule != address(0) &&
            tasks[taskId].items.length > 0
        ) {
            // uint256[] memory history = _getHistoryFingerprint(taskId);
            address detection = tasks[taskId].detectionModule;
            require(
                IDetectionModule(detection).beforeDetection(
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

    function getItemAuditInfo(
        uint256 itemId
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 taskId = itemsNFT[itemId].taskId;
        uint256 uploaded = tasks[taskId].items.length;
        uint256 allSupport;
        for (uint256 i = 0; i < uploaded; i++) {
            uint256 singleItem = tasks[taskId].items[i];
            allSupport += itemsNFT[singleItem].supporters.length;
        }
        return (
            uploaded,
            itemsNFT[itemId].supporters.length,
            itemsNFT[itemId].opponents.length,
            allSupport,
            itemsNFT[itemId].stateChangeTime
        );
    }

    /**
     * @notice 根据申请 ID 获得其所属的平台
     * @param taskId 申请/任务 ID
     * @return 申请所属的平台
     * label M18
     */
    function getPlatformByTaskId(
        uint256 taskId
    ) external view returns (address) {
        require(tasks[taskId].applicant != address(0), "181");
        return tasks[taskId].platform;
    }

    // label M19
    function getTaskPaymentModuleAndItemsLength(
        uint256 taskId
    ) public view returns (DataTypes.SettlementType, uint256) {
        return (tasks[taskId].settlement, tasks[taskId].items.length);
    }
}
