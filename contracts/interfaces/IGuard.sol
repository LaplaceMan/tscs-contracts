// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IGuard {
    function beforeSubmitItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId
    ) external view returns (bool);

    function beforeAuditItem(
        address caller,
        uint256 reputation,
        int256 deposit,
        uint256 requireId,
        DataTypes.AuditAttitude attitude
    ) external view returns (bool);
}
