/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-09 20:53:03
 * @Description: TSCS 内提供了三种结算策略, 本合约为一次性结算策略（0）, 特点是任何用户可为任何视频发出制作字幕的申请
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../../interfaces/ISubtitleSystem.sol";
import "../../interfaces/ISettlementStrategy.sol";

contract SettlementOneTime0 is ISettlementStrategy {
    /**
     * @notice TSCS 合约地址
     */
    address public subtitleSystem;
    /**
     * @notice 每一个结算策略为一次性结算（策略ID 为 0）的申请下, 被采纳的字幕都拥有相应的 SubtitleSettlement 结构, 这里是 applyId => SubtitleSettlement
     */
    mapping(uint256 => SubtitleSettlement) settlements;
    /**
     * @notice 每个被采纳且所属申请的结算策略为一次性结算的字幕, 都会在该结算策略合约中拥有相应的 SubtitleSettlement 结构体
     * @param settled 已经结算的稳定币数量
     * @param unsettled 未结算的稳定币数量
     */
    struct SubtitleSettlement {
        //此处均以稳定币计价, 这样做的好处是避免比率突然变化带来的影响
        uint256 settled;
        uint256 unsettled;
    }
    /**
     * @notice 仅能由 TSCS 调用
     */
    modifier auth() {
        require(msg.sender == subtitleSystem, "No Permission");
        _;
    }

    constructor(address ss) {
        subtitleSystem = ss;
    }

    /**
     * @notice 完成结算策略为一次性（0）的申请的结算（字幕制作费用）
     * @param applyId 结算策略为一次性结算（策略 ID 为 0）的申请 ID
     * @param platform 平台 Platform 的区块链地址
     * @param maker 字幕制作者（所有者）区块链地址
     * @param amount 此处为申请制作字幕时设置的支付稳定币数量（以相应 Platform 的稳定币计价）
     * @param auditorDivide 该 Platform 设置的审核员分成字幕制作者收益的比例
     * @param supporters 申请下被采纳字幕的支持者们
     * @return 本次结算所支付的字幕制作费用
     */
    function settlement(
        uint256 applyId,
        address platform,
        address maker,
        address,
        uint256 amount,
        uint256,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override auth returns (uint256) {
        if (settlements[applyId].settled < amount) {
            uint256 supporterGet = (amount * auditorDivide) / 65535;
            uint256 unit = supporterGet / supporters.length;

            ISubtitleSystem(subtitleSystem).preDivide(
                platform,
                maker,
                amount - unit * supporters.length
            );
            ISubtitleSystem(subtitleSystem).preDivideBatch(
                platform,
                supporters,
                unit
            );
            settlements[applyId].settled += amount;
        }
        return settlements[applyId].settled;
    }

    /**
     * @notice 更新相应申请下被采纳字幕的预期收益情况
     * @param applyId 结算策略为一次性结算（策略 ID 为 0）的申请 ID
     * @param amount 新增未结算稳定币
     */
    function updateDebtOrReward(uint256 applyId, uint256 amount) external auth {
        settlements[applyId].unsettled += amount;
    }

    /**
     * @notice 修改 TSCS 主合约调用地址
     * @param newSS 新的 TSCS 主合约地址
     */
    function changeTSCS(address newSS) external auth {
        subtitleSystem = newSS;
    }
}
