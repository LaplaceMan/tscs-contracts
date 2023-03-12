// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    function Murmes() external view returns (address);

    function fee() external view returns (uint16);

    function penalty() external view returns (uint256);

    function feeRecipient() external view returns (address);

    function updatePenalty(uint256 amount) external;

    function transferPenalty(
        address token,
        address to,
        uint256 amount
    ) external;

    event SystemSetFee(uint16 oldFee, uint16 newFee);
}
