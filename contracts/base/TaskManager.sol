// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./ItemManager.sol";
import "../interfaces/ISettlementModule.sol";

contract TaskManager is ItemManager {
    /**
     * @notice Murmes内已经存在的任务总数
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
     * @notice 该功能服务于后续的仲裁法庭，取消被确认的Item，相当于重新发出申请
     * @param taskId 被重置的申请 ID
     * @param amount 恢复的代币奖励数量（注意这里以代币计价）
     * Fn 2
     */
    function resetTask(uint256 taskId, uint256 amount) public auth {
        delete tasks[taskId].adopted;
        uint256 lockUpTime = IComponentGlobal(componentGlobal).lockUpTime();
        tasks[taskId].deadline = block.timestamp + lockUpTime;
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(tasks[taskId].settlement);
        ISettlementModule(settlement).resetSettlement(taskId, amount);
    }

    /**
     * @notice 取消申请
     * @param taskId 申请ewn ID
     * Fn 3
     */
    function cancelTask(uint256 taskId) external {
        require(msg.sender == tasks[taskId].applicant, "T35");
        require(
            tasks[taskId].adopted == 0 &&
                tasks[taskId].items.length == 0 &&
                block.timestamp >= tasks[taskId].deadline,
            "T36"
        );
        if (tasks[taskId].settlement == DataTypes.SettlementType.ONETIME) {
            require(
                IERC20(tasks[taskId].currency).transferFrom(
                    address(this),
                    msg.sender,
                    tasks[taskId].amount
                ),
                "T312"
            );
        }
        delete tasks[taskId];
    }

    // ***************** View Functions *****************
    function getPlatformAddressByTaskId(
        uint256 taskId
    ) external view returns (address) {
        require(tasks[taskId].applicant != address(0), "181");
        return tasks[taskId].platform;
    }

    function getTaskPaymentModuleAndItems(
        uint256 taskId
    ) public view returns (DataTypes.SettlementType, uint256[] memory) {
        return (tasks[taskId].settlement, tasks[taskId].items);
    }
}
