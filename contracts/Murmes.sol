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
import "./interfaces/IAuthorityModule.sol";

contract Murmes is TaskManager {
    constructor(address dao, address mutliSig) {
        _setOwner(dao);
        _setMutliSig(mutliSig);
        requiresNoteById.push("None");
    }

    /**
     * @notice 发布众包任务
     * @param vars 任务的信息和需求
     * @return 任务 ID
     * Fn 1
     */
    function postTask(
        DataTypes.PostTaskData calldata vars
    ) external returns (uint256) {
        require(
            vars.deadline > block.timestamp &&
                vars.requireId < requiresNoteById.length,
            "11"
        );

        _validatePostTaskData(
            vars.currency,
            vars.auditModule,
            vars.detectionModule
        );
        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);

        totalTasks++;
        address authority = IComponentGlobal(componentGlobal).authority();
        uint256 boxId = IAuthorityModule(authority).formatBoxIdOfPostTask(
            componentGlobal,
            vars.platform,
            vars.sourceId,
            vars.source,
            msg.sender,
            vars.settlement,
            vars.amount
        );
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
            uint256[] memory _tasks = IPlatforms(platforms).getBoxTasks(boxId);
            for (uint256 i = 0; i < _tasks.length; i++) {
                require(tasks[_tasks[i]].requireId != vars.requireId, "10");
            }
            uint256[] memory newTasks = _sortSettlementPriority(
                _tasks,
                vars.settlement,
                totalTasks
            );
            IPlatforms(platforms).updateBoxTasksByMurmes(boxId, newTasks);
        }

        if (vars.settlement != DataTypes.SettlementType.DIVIDEND) {
            address settlementModule = IModuleGlobal(moduleGlobal)
                .getSettlementModuleAddress(vars.settlement);
            ISettlementModule(settlementModule).updateDebtOrRevenue(
                totalTasks,
                0,
                vars.amount,
                0
            );
        }

        tasks[totalTasks].applicant = msg.sender;
        tasks[totalTasks].platform = vars.platform;
        tasks[totalTasks].sourceId = boxId;
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

    /**
     * @notice 完成任务后提交成果
     * @param vars 成果的信息
     * @return 成果ID
     * Fn 2
     */
    function submitItem(
        DataTypes.ItemMetadata calldata vars
    ) external returns (uint256) {
        require(tasks[vars.taskId].adopted == 0, "23");
        if (tasks[vars.taskId].items.length == 0) {
            require(block.timestamp <= tasks[vars.taskId].deadline, "26");
        }
        require(vars.requireId == tasks[vars.taskId].requireId, "29");

        _validateSubmitItemData(vars.taskId, vars.fingerprint);
        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);

        address guard = users[tasks[vars.taskId].applicant].guard;
        if (guard != address(0)) {
            require(
                IGuard(guard).beforeSubmitItem(
                    msg.sender,
                    users[msg.sender].reputation,
                    users[msg.sender].deposit,
                    vars.requireId
                ),
                "25"
            );
        }

        uint256 itemId = _createItem(msg.sender, vars);
        tasks[vars.taskId].items.push(itemId);

        _rewardMurmesToken(msg.sender);
        return itemId;
    }

    /**
     * @notice 审核/检测成果
     * @param itemId 成果的ID
     * @param attitude 检测结果，支持或反对
     * Fn 3
     */
    function auditItem(
        uint256 itemId,
        DataTypes.AuditAttitude attitude
    ) external {
        uint256 taskId = itemsNFT[itemId].taskId;
        require(taskId > 0, "31");
        require(tasks[taskId].adopted == 0, "33");

        _userInitialization(msg.sender, 0);
        _validateCaller(msg.sender);
        {
            address access = IComponentGlobal(componentGlobal).access();
            require(
                IAccessModule(access).auditable(users[msg.sender].deposit),
                "35"
            );
        }
        _evaluateItem(itemId, attitude, msg.sender);
        (
            uint256 uploaded,
            uint256 support,
            uint256 against,
            uint256 allSupport,
            uint256 uploadTime
        ) = getItemAuditData(itemId);
        DataTypes.ItemState state = IAuditModule(tasks[taskId].auditModule)
            .afterAuditItem(
                uploaded,
                support,
                against,
                allSupport,
                uploadTime,
                IComponentGlobal(componentGlobal).lockUpTime()
            );
        if (state != DataTypes.ItemState.NORMAL) {
            _changeItemState(itemId, state);
            _updateUsers(itemId, state);
            if (state == DataTypes.ItemState.ADOPTED) {
                tasks[taskId].adopted = itemId;
            }
        }
    }

    /**
     * @notice 预结算收益，众包任务的结算类型为：一次性
     * @param taskId 众包任务ID
     * Fn 4
     */
    function preExtractForNormal(uint256 taskId) external {
        require(
            tasks[taskId].settlement == DataTypes.SettlementType.ONETIME,
            "46"
        );
        _userInitialization(msg.sender, 0);
        address platforms = IComponentGlobal(componentGlobal).platforms();
        (, uint16 rateAuditorDivide) = IPlatforms(platforms).getPlatformRate(
            address(this)
        );
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(DataTypes.SettlementType.ONETIME);
        address itemNFT = IComponentGlobal(componentGlobal).itemToken();
        uint256 adoptedItemId = tasks[taskId].adopted;
        ISettlementModule(settlement).settlement(
            taskId,
            tasks[taskId].currency,
            IItemNFT(itemNFT).ownerOf(adoptedItemId),
            0,
            rateAuditorDivide,
            itemsNFT[adoptedItemId].supporters
        );
    }

    /**
     * @notice 预结算Box收益，同时完成众包任务结算
     * @param boxId Box ID
     * Fn 5
     */
    function preExtractOther(uint256 boxId) external {
        address platforms = IComponentGlobal(componentGlobal).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.unsettled > 0, "511");
        _userInitialization(msg.sender, 0);
        DataTypes.PlatformStruct memory platform = IPlatforms(platforms)
            .getPlatform(box.platform);
        uint256 unsettled = (platform.rateCountsToProfit *
            box.unsettled *
            (10 ** 6)) / BASE_RATE;
        uint256 surplus = _ergodic(
            boxId,
            unsettled,
            platforms,
            platform.rateAuditorDivide
        );
        address platformToken = IComponentGlobal(componentGlobal)
            .platformToken();
        if (surplus > 0) {
            IPlatformToken(platformToken).mintPlatformTokenByMurmes(
                platform.platformId,
                box.creator,
                surplus
            );
        }
        IPlatforms(platforms).updateBoxUnsettledRevenueByMurmes(
            boxId,
            int256(box.unsettled) * -1
        );
    }

    /**
     * @notice 提取锁定的代币/收益
     * @param platform 所属平台/代币类型
     * @param day 解锁的日期
     * @return 减去手续费外，提取的代币总数
     * Fn 6
     */
    function withdraw(
        address platform,
        uint256[] memory day
    ) external returns (uint256) {
        _userInitialization(msg.sender, 0);

        uint256 all = 0;
        for (uint256 i = 0; i < day.length; i++) {
            if (
                users[msg.sender].locks[platform][day[i]] > 0 &&
                block.timestamp >
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
                if (platformInfo.platformId > 0) {
                    IPlatformToken(platformToken).mintPlatformTokenByMurmes(
                        platformInfo.platformId,
                        recipient,
                        thisFee
                    );
                } else {
                    require(
                        IERC20(platform).transfer(recipient, thisFee),
                        "612"
                    );
                }
            }

            if (platformInfo.platformId > 0) {
                IPlatformToken(platformToken).mintPlatformTokenByMurmes(
                    platformInfo.platformId,
                    msg.sender,
                    all
                );
            } else {
                require(IERC20(platform).transfer(msg.sender, all), "6122");
            }
        }
        return all;
    }

    /**
     * @notice 更新Item收益
     * @param taskId Item所属任务ID
     * @param counts 更新的收益
     * Fn 7
     */
    function updateItemRevenue(uint256 taskId, uint256 counts) external {
        require(
            isOperator(msg.sender) || msg.sender == tasks[taskId].platform,
            "75"
        );
        require(
            tasks[taskId].settlement == DataTypes.SettlementType.DIVIDEND,
            "76"
        );

        address platforms = IComponentGlobal(componentGlobal).platforms();
        (uint16 rateCountsToProfit, ) = IPlatforms(platforms).getPlatformRate(
            tasks[taskId].platform
        );
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(tasks[taskId].settlement);
        ISettlementModule(settlement).updateDebtOrRevenue(
            taskId,
            counts,
            tasks[taskId].amount,
            rateCountsToProfit
        );
    }

    /**
     * @notice 更新单个利益相关者的收益情况，更新后的收益为锁定状态
     * @param platform 所属平台/代币类型
     * @param to 收益/代币接收方
     * @param amount 收益/代币数目
     * Fn 8
     */
    function preDivideBySettlementModule(
        address platform,
        address to,
        uint256 amount
    ) external auth {
        _preDivide(platform, to, amount);
    }

    /**
     * @notice 更新多个利益相关者的收益情况，更新后的收益为锁定状态
     * @param platform 所属平台/代币类型
     * @param to 收益/代币接收方
     * @param amount 收益/代币数目
     * Fn 9
     */
    function preDivideBatchBySettlementModule(
        address platform,
        address[] memory to,
        uint256 amount
    ) external auth {
        _preDivideBatch(platform, to, amount);
    }

    /**
     * @notice 根据Item状态变化更新多个利益相关者的信息
     * @param itemId 唯一标识Item的ID
     * @param state Item更新后的状态
     * Fn 10
     */
    function _updateUsers(uint256 itemId, DataTypes.ItemState state) internal {
        int8 flag = 1;
        uint8 reverseState = (uint8(state) == 1 ? 2 : 1);
        if (state == DataTypes.ItemState.DELETED) flag = -1;
        address access = IComponentGlobal(componentGlobal).access();

        {
            uint8 multiplier = IAccessModule(access).multiplier();
            address itemToken = IComponentGlobal(componentGlobal).itemToken();
            address owner = IItemNFT(itemToken).ownerOf(itemId);
            _updateUser(owner, access, flag, uint8(state), multiplier);
        }

        for (uint256 i = 0; i < itemsNFT[itemId].supporters.length; i++) {
            address supporter = itemsNFT[itemId].supporters[i];
            _updateUser(supporter, access, flag, uint8(state), 100);
        }

        for (uint256 i = 0; i < itemsNFT[itemId].opponents.length; i++) {
            address opponent = itemsNFT[itemId].opponents[i];
            _updateUser(opponent, access, flag * (-1), reverseState, 100);
        }
    }

    /**
     * @notice 根据Item状态变化更新利益相关者的信息
     * @param user 利益相关者
     * @param access access模块合约地址
     * @param flag 默认判断标志
     * @param state 状态
     * @param multiplier 奖惩倍数
     * Fn 11
     */
    function _updateUser(
        address user,
        address access,
        int8 flag,
        uint8 state,
        uint8 multiplier
    ) internal {
        (uint256 reputationDValue, uint256 tokenDValue) = IAccessModule(access)
            .variation(users[user].reputation, state);
        _updateUser(
            user,
            int256((reputationDValue * multiplier) / 100) * flag,
            int256((tokenDValue * multiplier) / 100) * flag
        );
    }

    /**
     * @notice 遍历结算Box的所有众包任务
     * @param boxId 唯一标识Box的ID
     * @param unsettled 可支付代币数目
     * @param platforms platform组件合约地址
     * @param rateAuditorDivide 审核分成比率
     * Fn 12
     */
    function _ergodic(
        uint256 boxId,
        uint256 unsettled,
        address platforms,
        uint16 rateAuditorDivide
    ) internal returns (uint256) {
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        address itemNFT = IComponentGlobal(componentGlobal).itemToken();
        for (uint256 i = 0; i < box.tasks.length; i++) {
            uint256 taskId = box.tasks[i];
            if (tasks[taskId].adopted > 0 && unsettled > 0) {
                address settlement = IModuleGlobal(moduleGlobal)
                    .getSettlementModuleAddress(tasks[taskId].settlement);
                uint256 itemGetRevenue = ISettlementModule(settlement)
                    .settlement(
                        taskId,
                        box.platform,
                        IItemNFT(itemNFT).ownerOf(tasks[taskId].adopted),
                        unsettled,
                        rateAuditorDivide,
                        itemsNFT[tasks[taskId].adopted].supporters
                    );
                unsettled -= itemGetRevenue;
            }
        }
        return unsettled;
    }

    /**
     * @notice 根据结算策略的优先级保持Box众包任务集合的有序性
     * @param arr 众包任务ID集合
     * @param spot 新的众包任务的结算策略
     * @param id 新的众包任务的ID
     * @return 针对特定Box排好序的众包任务集合
     * Fn 13
     */
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

    /**
     * @notice 奖励用户ID为0的PlatformToken
     * @param to 接收代币地址
     * Fn 14
     */
    function _rewardMurmesToken(address to) internal {
        address platformToken = IComponentGlobal(componentGlobal)
            .platformToken();
        IPlatformToken(platformToken).mintPlatformTokenByMurmes(
            0,
            to,
            users[msg.sender].reputation
        );
    }

    /**
     * @notice 发起新的众包任务时对用于支付的代币和模块进行检测
     * @param currency 用于支付的代币类型
     * @param audit 审计合约
     * @param detection 检测合约
     * Fn 15
     */
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
            ),
            "156"
        );
    }

    /**
     * @notice 根据信誉度分数和质押资产数判断调用者是否有调用权限
     * @param caller 调用者地址
     * Fn 16
     */
    function _validateCaller(address caller) internal view {
        address access = IComponentGlobal(componentGlobal).access();
        require(
            IAccessModule(access).access(
                users[caller].reputation,
                users[caller].deposit
            ),
            "165"
        );
    }

    /**
     * @notice 根据众包任务中设置的检测逻辑，判断新提交的Item是否符合要求
     * @param taskId 所属的众包任务ID
     * @param fingerprint 新上传Item的指纹值
     * Fn 17
     */
    function _validateSubmitItemData(
        uint256 taskId,
        uint256 fingerprint
    ) internal view {
        if (
            tasks[taskId].detectionModule != address(0) &&
            tasks[taskId].items.length > 0
        ) {
            address detection = tasks[taskId].detectionModule;
            require(
                IDetectionModule(detection).detectionInSubmitItem(
                    taskId,
                    fingerprint
                ),
                "176"
            );
        }
    }

    // ***************** View Functions *****************
    function getItemAuditData(
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

    function getItemCustomModuleOfTask(
        uint256 itemId
    ) external view returns (address, address, address) {
        uint256 taskId = itemsNFT[itemId].taskId;
        return (
            tasks[taskId].currency,
            tasks[taskId].auditModule,
            tasks[taskId].detectionModule
        );
    }
}
