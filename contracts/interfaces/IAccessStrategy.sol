// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessStrategy {
    function spread(uint256 repution, uint8 flag)
        external
        view
        returns (
            uint256,
            uint256,
            uint8
        );

    function access(uint256 repution, uint256 deposit)
        external
        view
        returns (bool);
}
