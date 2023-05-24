// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAuditModule {
    function Murmes() external view returns (address);

    function name() external view returns (string memory);

    function auditUnit() external view returns (uint256);

    function afterAuditItem(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view returns (DataTypes.ItemState);

    event SetAuditUnit(uint256 nowAuditUnit);
}
