// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthorityBase.sol";

contract MurmesAuthority is IAuthorityBase {
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
}
