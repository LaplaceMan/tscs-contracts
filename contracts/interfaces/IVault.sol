// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function Murmes() external view returns (address);

    function fee() external view returns (uint16);

    function feeRecipient() external view returns (address);

    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) external;
}
