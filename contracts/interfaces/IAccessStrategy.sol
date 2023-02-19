// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccessStrategy {
    function spread(uint256 reputation, uint8 flag)
        external
        view
        returns (uint256, uint256);

    function access(uint256 reputation, int256 deposit)
        external
        view
        returns (bool);

    function auditable(int256 deposit_) external view returns (bool);

    function depositThreshold() external view returns (uint16);

    function blacklistThreshold() external view returns (uint8);

    function minDeposit() external view returns (uint256);

    function rewardToken() external view returns (uint256);

    function punishmentToken() external view returns (uint256);

    function multiplier() external view returns (uint8);

    function reward(uint256 reputation) external pure returns (uint256);

    function punishment(uint256 reputation) external view returns (uint256);

    function lastReputation(uint256 reputation, uint8 flag)
        external
        pure
        returns (uint256);

    function deposit(uint256 reputation) external view returns (uint256);
}
