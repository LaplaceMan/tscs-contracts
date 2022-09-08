// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDetectionStrategy {
    function detection(uint256 origin, uint256[] memory history)
        external
        view
        returns (bool);
}
