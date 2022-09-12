// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettlementStrategy {
    function settlement(
        uint256 applyId,
        address platform,
        address maker,
        address creator,
        uint256 amount,
        uint256 countsToProfit,
        uint16 auditorDivide,
        address[] memory supporters
    ) external returns (uint256);

    function updateDebtOrReward(uint256 applyId, uint256 amount) external;
}
