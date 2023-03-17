// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGuard {
    function beforeSubmitItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId
    ) external view returns (bool);

    function beforeAuditItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId
    ) external view returns (bool);
}
