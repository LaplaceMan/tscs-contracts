// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISubtitleSystem {
    function preDivide(
        address platform,
        address to,
        uint256 amount
    ) external;

    function preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) external;
}
