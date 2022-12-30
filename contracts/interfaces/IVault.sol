// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function penalty() external view returns (uint256);

    function Murmes() external view returns (address);

    function changePenalty(uint256 amount) external;

    function addFee(uint256 platformId, uint256 amount) external;

    function getFeeIncome(uint256 platformId) external view returns (uint256);

    function withdrawDeposit(
        address token,
        address to,
        uint256 amount
    ) external;

    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) external;
}
