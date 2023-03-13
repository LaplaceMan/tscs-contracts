// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IModuleGlobal {
    function Murmes() external view returns (address);

    function isAuditModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isDetectionModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isGuardModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isAuthorityModuleWhitelisted(
        address module
    ) external view returns (bool);

    function isCurrencyWhitelisted(
        address currency
    ) external view returns (bool);

    function isPostTaskModuleValid(
        address currency,
        address audit,
        address detection
    ) external view returns (bool);

    function getSettlementModuleAddress(
        DataTypes.SettlementType moduleId
    ) external view returns (address);

    event SystemSetCurrencyIsWhitelisted(address token, bool result);
    event SystemSetGuardModuleIsWhitelisted(address guard, bool result);
    event SystemSetAuditModuleIsWhitelisted(address module, bool result);
    event SystemSetDetectionModuleIsWhitelisted(address module, bool result);
    event SystemSetAuthorityModuleIsWhitelisted(address module, bool result);
    event SystemSetSettlementModule(
        DataTypes.SettlementType moduleId,
        address module
    );
}
