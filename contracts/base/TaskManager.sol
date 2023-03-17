// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./ItemManager.sol";
import "../interfaces/IModuleGlobal.sol";
import "../interfaces/ISettlementModule.sol";

contract TaskManager is ItemManager {
    /**
     * @notice Murmes已经存在的众包任务总数
     */
    uint256 public totalTasks;
    /**
     * @notice task的信息, 从1开始（提交任务的顺位）
     */
    mapping(uint256 => DataTypes.TaskStruct) public tasks;

    /**
     * @notice 更新（增加）任务中的额度和（延长）到期时间
     * @param taskId 申请顺位 ID
     * @param plusAmount 增加支付额度
     * @param plusTime 延长到期时间
     * Fn 1
     */
    function updateTask(
        uint256 taskId,
        uint256 plusAmount,
        uint256 plusTime
    ) public {
        require(msg.sender == tasks[taskId].applicant, "T15");
        require(tasks[taskId].adopted == 0, "T10");
        tasks[taskId].amount += plusAmount;
        tasks[taskId].deadline += plusTime;
        require(tasks[taskId].deadline > block.timestamp + 1 days, "T11");
        if (tasks[taskId].settlement == DataTypes.SettlementType.ONETIME) {
            IERC20(tasks[taskId].currency).transferFrom(
                msg.sender,
                address(this),
                plusAmount
            );
        } else if (
            tasks[taskId].settlement ==
            DataTypes.SettlementType.ONETIME_MORTGAGE
        ) {
            address settlementModule = IModuleGlobal(moduleGlobal)
                .getSettlementModuleAddress(
                    DataTypes.SettlementType.ONETIME_MORTGAGE
                );
            ISettlementModule(settlementModule).updateDebtOrRevenue(
                taskId,
                0,
                plusAmount,
                0
            );
        }
    }

    /**
     * @notice 取消任务
     * @param taskId 众包任务ID
     * Fn 2
     */
    function cancelTask(uint256 taskId) external {
        require(msg.sender == tasks[taskId].applicant, "T25");
        require(
            tasks[taskId].adopted == 0 &&
                tasks[taskId].items.length == 0 &&
                block.timestamp >= tasks[taskId].deadline,
            "T26"
        );
        if (tasks[taskId].settlement == DataTypes.SettlementType.ONETIME) {
            require(
                IERC20(tasks[taskId].currency).transferFrom(
                    address(this),
                    msg.sender,
                    tasks[taskId].amount
                ),
                "T212"
            );
        }
        delete tasks[taskId];
    }

    /**
     * @notice 该功能服务于后续的仲裁法庭，取消被确认的Item，相当于重新发出申请
     * @param taskId 被重置的申请 ID
     * @param amount 恢复的代币奖励数量（注意这里以代币计价）
     * Fn 3
     */
    function resetTask(uint256 taskId, uint256 amount) public auth {
        delete tasks[taskId].adopted;
        uint256 lockUpTime = IComponentGlobal(componentGlobal).lockUpTime();
        tasks[taskId].deadline = block.timestamp + lockUpTime;
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(tasks[taskId].settlement);
        ISettlementModule(settlement).resetSettlement(taskId, amount);
    }

    // ***************** View Functions *****************
    function getPlatformAddressByTaskId(uint256 taskId)
        external
        view
        returns (address)
    {
        require(tasks[taskId].applicant != address(0), "181");
        return tasks[taskId].platform;
    }

    function getTaskSettlementModuleAndItems(uint256 taskId)
        external
        view
        returns (DataTypes.SettlementType, uint256[] memory)
    {
        return (tasks[taskId].settlement, tasks[taskId].items);
    }

    function getTaskItemsState(uint256 taskId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            tasks[taskId].items.length,
            tasks[taskId].adopted,
            tasks[taskId].deadline
        );
    }

    function getAdoptedItemData(uint256 taskId)
        external
        view
        returns (
            uint256,
            address,
            address[] memory
        )
    {
        return (
            tasks[taskId].adopted,
            tasks[taskId].currency,
            itemsNFT[tasks[taskId].adopted].supporters
        );
    }

    function getTaskSettlementData(uint256 taskId)
        external
        view
        returns (
            DataTypes.SettlementType,
            address,
            uint256
        )
    {
        return (
            tasks[taskId].settlement,
            tasks[taskId].currency,
            tasks[taskId].amount
        );
    }

    function getItemCustomModuleOfTask(uint256 itemId)
        external
        view
        returns (
            address,
            address,
            address
        )
    {
        uint256 taskId = itemsNFT[itemId].taskId;
        return (
            tasks[taskId].currency,
            tasks[taskId].auditModule,
            tasks[taskId].detectionModule
        );
    }

    function getItemAuditData(uint256 itemId)
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
}
