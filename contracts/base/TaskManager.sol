/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-08 15:13:26
 * @Description: 管理 Murmes 所使用的审核策略、访问策略、检测策略和结算策略
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "./ItemManager.sol";

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
    function updateApplication(
        uint256 taskId,
        uint256 plusAmount,
        uint256 plusTime
    ) public {
        require(msg.sender == tasks[taskId].applicant, "T15");
        require(tasks[taskId].adopted == 0, "T10");
        if (tasks[taskId].deadline == 0) {
            tasks[taskId].amount = plusAmount;
            tasks[taskId].deadline = plusTime;
            require(plusTime > block.timestamp + 1 days, "161");
        } else {
            tasks[taskId].amount += plusAmount;
            tasks[taskId].deadline += plusTime;
        }
        // if (tasks[taskId].strategy == 0) {
        //     require();
        // IZimu(zimuToken).transferFrom(
        //     msg.sender,
        //     address(this),
        //     plusAmount
        // ),
        // "1612"
        // }
    }

    /**
     * @notice 该功能服务于后续的仲裁法庭，取消被确认的恶意字幕，相当于重新发出申请
     * @param taskId 被重置的申请 ID
     * @param amount 恢复的代币奖励数量（注意这里以代币计价）
     * label M17
     */
    function resetApplication(uint256 taskId, uint256 amount) public auth {
        delete tasks[taskId].adopted;
        // tasks[taskId].deadline = block.timestamp + lockUpTime;
        // ISettlementStrategy(settlementStrategy[tasks[taskId].strategy].strategy)
        //     .resetSettlement(taskId, amount);
    }

    /**
     * @notice 取消申请（仅支持一次性结算策略, 其它的自动冻结）
     * @param taskId 申请 ID
     * label M15
     */
    function cancel(uint256 taskId) external {
        // require(msg.sender == tasks[taskId].applicant, "155");
        // require(
        //     tasks[taskId].adopted == 0 &&
        //         // tasks[taskId].subtitles.length == 0 &&
        //         // tasks[taskId].deadline <= block.timestamp,
        //     "1552"
        // );
        // tasks[taskId].deadline = 0;
        // if (tasks[taskId].strategy == 0) {
        // require(
        //     IZimu(zimuToken).transferFrom(
        //         address(this),
        //         msg.sender,
        //         tasks[taskId].amount
        //     ),
        //     "1512"
        // );
        // }
    }
}
