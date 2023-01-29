// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGuard {
    function check(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint32 languageId
    ) external view returns (bool);
}
