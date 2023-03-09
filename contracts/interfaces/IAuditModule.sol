// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IAuditModule {
    function auditUnit() external view returns (uint256);

    function auditResult(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport,
        uint256 uploadTime,
        uint256 lockUpTime
    ) external view returns (DataTypes.ItemState);
}
