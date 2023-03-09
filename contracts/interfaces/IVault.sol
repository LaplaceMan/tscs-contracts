// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function fee() external view returns (uint16);

    function penalty() external view returns (uint256);

    function Murmes() external view returns (address);

    function feeRecipient() external view returns (address);

    function updatePenalty(uint256 amount) external;

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
