// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthorityBase.sol";

contract MurmesAuthority is IAuthorityBase {
    // Fn 1
    function forPostTask(
        address,
        uint256 boxId,
        string memory source,
        address,
        DataTypes.SettlementType settlement
    ) external override returns (uint256) {
        require(settlement == DataTypes.SettlementType.ONETIME, "MA16");
        require(bytes(source).length > 0, "MA11");
        return boxId;
    }

    // Fn 2
    function forCreateBox(
        address,
        uint256,
        address
    ) external view override returns (bool) {
        return false;
    }

    // Fn 3
    function forUpdateBoxRevenue(
        uint256,
        uint256,
        address,
        address
    ) external override returns (uint256) {
        return 0;
    }
}
