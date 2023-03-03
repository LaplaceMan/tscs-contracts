// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IModuleGlobal {
    function isAuditModuleWhitelisted(address module)
        external
        view
        returns (bool);

    function isDetectionModuleWhitelisted(address module)
        external
        view
        returns (bool);

    function isGuardWhitelisted(address module) external view returns (bool);

    function isCurrencyWhitelisted(address currency)
        external
        view
        returns (bool);

    function isPostTaskModuleValid(
        address currency,
        address audit,
        address detection
    ) external view returns (bool);

    function getSettlementModuleAddress(DataTypes.SettlementType moduleId)
        external
        view
        returns (address);
}
