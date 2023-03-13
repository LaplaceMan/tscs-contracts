// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISettlementModule {
    function Murmes() external view returns (address);

    function settlement(
        uint256 taskId,
        address platform,
        address maker,
        uint256 unsettled,
        uint16 auditorDivide,
        address[] memory supporters
    ) external returns (uint256);

    function updateDebtOrRevenue(
        uint256 taskId,
        uint256 number,
        uint256 amount,
        uint16 rateCountsToProfit
    ) external;

    function resetSettlement(uint256 taskId, uint256 amount) external;

    function getSettlementBaseData(
        uint256 taskId
    ) external view returns (uint256, uint256);
}
