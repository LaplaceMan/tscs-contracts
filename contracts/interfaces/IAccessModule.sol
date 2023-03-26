// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Constant} from "../libraries/Constant.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAccessModule {
    function Murmes() external returns (address);

    function variation(
        uint256 reputation,
        uint8 flag
    ) external view returns (uint256, uint256);

    function access(
        uint256 reputation,
        int256 deposit
    ) external view returns (bool);

    function auditable(int256 deposit_) external view returns (bool);

    function depositUnit() external view returns (uint256);

    function punishmentUnit() external view returns (uint256);

    function multiplier() external view returns (uint8);

    function reward(uint256 reputation) external pure returns (uint256);

    function punishment(uint256 reputation) external view returns (uint256);

    function lastReputation(
        uint256 reputation,
        uint8 flag
    ) external pure returns (uint256);

    function deposit(uint256 reputation) external view returns (uint256);

    event MurmesSetMultiplier(uint8 newMultiplier);
    event MurmesSetDepositUnit(uint256 newMinDepositUnit);
    event MurmesSetPunishmentUnit(uint256 newPunishmentTokenUnit);
}
