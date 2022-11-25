// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettlementStrategy {
    function settlement(
        uint256 applyId,
        address platform,
        address maker,
        uint256 unsettled,
        uint16 auditorDivide,
        address[] memory supporters
    ) external returns (uint256);

    function updateDebtOrReward(
        uint256 applyId,
        uint256 number,
        uint256 amount,
        uint16 rateCountsToProfit
    ) external;

    function subtitleSystem() external view returns (address);

    function resetSettlement(uint256 applyId, uint256 amount) external;
}
