// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
import "../interfaces/IComponentGlobal.sol";

interface MurmesInterface {
    function componentGlobal() external view returns (address);

    function owner() external view returns (address);
}

contract DefaultAuthority is IAuthorityBase {
    address public Murmes;

    constructor(address ms) {
        Murmes = ms;
    }

    // Fn 1
    function forPostTask(
        address,
        uint256 boxId,
        string memory,
        address caller,
        DataTypes.SettlementType
    ) external override returns (uint256) {
        address components = MurmesInterface(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.creator == caller, "DA15");
        return boxId;
    }

    // Fn 2
    function forCreateBox(
        address platform,
        uint256 platformId,
        address caller
    ) external returns (bool) {
        if (caller != platform || platformId == 0) {
            return false;
        } else {
            return true;
        }
    }

    // Fn 3
    function forUpdateBoxRevenue(
        uint256,
        uint256 counts,
        address platform,
        address caller
    ) external override returns (uint256) {
        require(platform == caller, "DA35");
        return counts;
    }
}
