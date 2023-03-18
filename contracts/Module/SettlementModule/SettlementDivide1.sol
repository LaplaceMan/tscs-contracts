// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../../interfaces/ISettlementModule.sol";

interface MurmesInterface {
    function preDivideBySettlementModule(
        address platform,
        address to,
        uint256 amount
    ) external;

    function preDivideBatchBySettlementModule(
        address platform,
        address[] memory to,
        uint256 amount
    ) external;
}

contract SettlementDivide1 is ISettlementModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 记录每个Item的详细结算信息
     */
    mapping(uint256 => ItemSettlement) settlements;

    constructor(address ms) {
        Murmes = ms;
    }

    // Fn 1
    modifier auth() {
        require(msg.sender == Murmes, "SD15");
        _;
    }

    /**
     * @notice 完成结算策略为分成的申请的结算
     * @param taskId 结算策略为一次性结算的申请ID
     * @param platform 任务所属平台的区块链地址
     * @param maker Item制作者区块链地址
     * @param unsettled Box剩余收益
     * @param auditorDivide 该平台设置的审核员分成Item制作者收益的比例
     * @param supporters 申请下被采纳Item的支持者们
     * @return 本次结算所支付的Item制作费用
     * Fn 2
     */
    function settlement(
        uint256 taskId,
        address platform,
        address maker,
        uint256 unsettled,
        uint16 auditorDivide,
        address[] memory supporters
    ) external override auth returns (uint256) {
        uint256 itemGet;
        if (settlements[taskId].unsettled > 0) {
            if (unsettled >= settlements[taskId].unsettled) {
                itemGet = settlements[taskId].unsettled;
            } else {
                itemGet = unsettled;
            }

            uint256 divide = ((itemGet * auditorDivide) /
                Constant.BASE_RATE /
                supporters.length);
            MurmesInterface(Murmes).preDivideBatchBySettlementModule(
                platform,
                supporters,
                divide
            );
            MurmesInterface(Murmes).preDivideBySettlementModule(
                platform,
                maker,
                itemGet - divide * supporters.length
            );
            settlements[taskId].settled += itemGet;
            settlements[taskId].unsettled -= itemGet;
        }
        return itemGet;
    }

    /**
     * @notice 更新相应申请下被采纳Item的预期收益情况
     * @param taskId 结算策略为分成结算的申请ID
     * @param number Box新增收益
     * @param amount 申请中设置的支付代币数
     * @param rateCountsToProfit 所属平台设定的审核人员分成比例
     * Fn 3
     */
    function updateDebtOrRevenue(
        uint256 taskId,
        uint256 number,
        uint256 amount,
        uint16 rateCountsToProfit
    ) external override auth {
        uint256 unpaidToken0 = (rateCountsToProfit * number * (10 ** 6)) /
            Constant.BASE_RATE;
        uint256 unpaidToken1 = (unpaidToken0 * amount) / Constant.BASE_RATE;
        settlements[taskId].unsettled += unpaidToken1;
    }

    /**
     * @notice 更改特定申请的未结算代币数，为仲裁服务
     * @param taskId 申请的 ID
     * @param amount 恢复的代币数量
     * Fn 4
     */
    function resetSettlement(
        uint256 taskId,
        uint256 amount
    ) external override auth {
        settlements[taskId].unsettled += amount;
        settlements[taskId].settled -= amount;
    }

    // ***************** View Functions *****************
    function getItemSettlement(
        uint256 taskId
    ) external view override returns (ItemSettlement memory) {
        return settlements[taskId];
    }
}
