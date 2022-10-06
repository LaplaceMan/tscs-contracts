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

    function access(uint256 repution, int256 deposit)
        external
        view
        returns (bool);

    function baseRatio() external view returns (uint16);

    function depositThreshold() external view returns (uint16);

    function blacklistThreshold() external view returns (uint8);

    function minDeposit() external view returns (uint256);

    function rewardToken() external view returns (uint256);

    function punishmentToken() external view returns (uint256);

    function multiplier() external view returns (uint8);

    function opeator() external view returns (address);
}
