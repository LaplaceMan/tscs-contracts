// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IModuleGlobal.sol";

contract ModuleGlobal is IModuleGlobal {
    address public defaultAuditModule;

    address public defaultDetectionModule;

    mapping(address => bool) whitelistAuditModule;

    mapping(address => bool) whitelistDetectionModule;

    mapping(address => bool) whitelistPersonalGuard;

    mapping(DataTypes.SettlementType => address) settlementModule;

    mapping(address => bool) whitelistCurrency;

    event SystemSetDefaultModule(uint8 note, address module);
    event SystemSetSettlementModule(
        DataTypes.SettlementType moduleId,
        address module
    );

    function setSettlementModule(
        DataTypes.SettlementType moduleId,
        address module
    ) external {
        require(module != address(0), "S21");
        settlementModule[moduleId] = module;
        emit SystemSetSettlementModule(moduleId, module);
    }

    function isAuditModuleWhitelisted(address module)
        external
        view
        returns (bool)
    {
        return whitelistAuditModule[module];
    }

    function isDetectionModuleWhitelisted(address module)
        external
        view
        returns (bool)
    {
        return whitelistDetectionModule[module];
    }

    function isGuardWhitelisted(address module) external view returns (bool) {
        return whitelistPersonalGuard[module];
    }

    function isCurrencyWhitelisted(address currency)
        external
        view
        returns (bool)
    {
        return whitelistCurrency[currency];
    }

    function isPostTaskModuleValid(
        address currency,
        address audit,
        address detection
    ) external view returns (bool) {
        bool can = true;
        if (
            !whitelistCurrency[currency] ||
            !whitelistAuditModule[audit] ||
            !whitelistDetectionModule[detection]
        ) {
            can = false;
        }
        return can;
    }

    function getSettlementModuleAddress(DataTypes.SettlementType moduleId)
        external
        view
        returns (address)
    {
        return settlementModule[moduleId];
    }
}
