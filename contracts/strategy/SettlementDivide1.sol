/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-11 17:01:11
 * @Description: Murmes 内提供了三种结算策略, 本合约为分成结算策略（1）
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IMurmes.sol";
import "../interfaces/ISettlementStrategy.sol";

contract SettlementDivide1 is ISettlementStrategy {
    uint16 constant RATE_BASE = 65535;
    /**
     * @notice Murmes 合约地址
     */
    address public Murmes;
    /**
     * @notice 每一个结算策略为分成结算（策略ID 为 1）的申请下, 被采纳的字幕都拥有相应的 SubtitleSettlement 结构, 这里是 taskId => SubtitleSettlement
     */
    mapping(uint256 => SubtitleSettlement) settlements;
    /**
     * @notice 每个被采纳且所属申请的结算策略为分成结算的字幕, 都会在该结算策略合约中拥有相应的 SubtitleSettlement 结构体
     * @param settled 已经结算的稳定币数量
     * @param unsettled 未结算的稳定币数量
     */
    struct SubtitleSettlement {
        //此处均以稳定币计价, 这样做的好处是避免比率突然变化带来的影响，字幕使用量
        uint256 settled;
        uint256 unsettled;
    }
    /**
     * @notice 仅能由 Murmes 调用
     */
    modifier auth() {
        require(msg.sender == Murmes, "ER5");
        _;
    }

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 完成结算策略为分成（1）的申请的结算（字幕制作费用）
     * @param taskId 结算策略为一次性结算的申请 ID
     * @param platform 平台 Platform 的区块链地址
     * @param maker 字幕制作者（所有者）区块链地址
     * @param unsettled 视频剩余收益
     * @param auditorDivide 该 Platform 设置的审核员分成字幕制作者收益的比例
     * @param supporters 申请下被采纳字幕的支持者们
     * @return 本次结算所支付的字幕制作费用
     */
    function settlement(
        uint256 taskId,
        address platform,
        address maker,
        uint256 unsettled,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override auth returns (uint256) {
        uint256 subtitleGet;
        if (settlements[taskId].unsettled > 0) {
            if (unsettled >= settlements[taskId].unsettled) {
                subtitleGet = settlements[taskId].unsettled;
            } else {
                subtitleGet = unsettled;
            }

            uint256 divide = ((subtitleGet * auditorDivide) /
                65535 /
                supporters.length);
            IMurmes(Murmes).preDivideBatch(platform, supporters, divide);
            IMurmes(Murmes).preDivide(
                platform,
                maker,
                subtitleGet - divide * supporters.length
            );
            settlements[taskId].settled += subtitleGet;
            settlements[taskId].unsettled -= subtitleGet;
        }
        return subtitleGet;
    }

    /**
     * @notice 更新相应申请下被采纳字幕的预期收益情况
     * @param taskId 结算策略为分成结算（策略 ID 为 1）的申请 ID
     * @param number 新增视频播放量
     * @param amount 申请中设置的支付代币数
     * @param rateCountsToProfit 平台Platform设定的审核人员分成比例
     */
    function updateDebtOrReward(
        uint256 taskId,
        uint256 number,
        uint256 amount,
        uint16 rateCountsToProfit
    ) external auth {
        uint256 unpaidToken0 = (rateCountsToProfit * number * (10**6)) /
            RATE_BASE;
        uint256 unpaidToken1 = (unpaidToken0 * amount) / RATE_BASE;
        settlements[taskId].unsettled += unpaidToken1;
    }

    /**
     * @notice 更改特定申请的未结算代币数，为仲裁服务
     * @param taskId 申请的 ID
     * @param amount 恢复的代币数量
     */
    function resetSettlement(uint256 taskId, uint256 amount) external auth {
        settlements[taskId].unsettled += amount;
        settlements[taskId].settled -= amount;
    }

    /**
     * @notice 获得特定申请（任务）的最新结算情况
     * @param taskId 申请的 ID
     * @return 已结算代币数和未结算代币数
     */
    function getSettlementBaseInfo(uint256 taskId)
        external
        view
        returns (uint256, uint256)
    {
        return (settlements[taskId].settled, settlements[taskId].unsettled);
    }
}
