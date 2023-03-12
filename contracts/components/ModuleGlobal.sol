// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IModuleGlobal.sol";

contract ModuleGlobal is IModuleGlobal {
    address public Murmes;

    mapping(address => bool) whitelistAuditModule;

    mapping(address => bool) whitelistGuardModule;

    mapping(address => bool) whitelistDetectionModule;

    mapping(DataTypes.SettlementType => address) settlementModule;

    mapping(address => bool) whitelistCurrency;

    event SystemSetSettlementModule(
        DataTypes.SettlementType moduleId,
        address module
    );

    constructor(address ms) {
        Murmes = ms;
    }

    // Fn 1
    modifier auth() {
        require(IMurmes(Murmes).owner() == msg.sender, "M15");
        _;
    }

    /**
     * @notice 设置执行结算逻辑的合约地址
     * @param moduleId 结算类型
     * @param module 合约地址
     * Fn 2
     */
    function setSettlementModule(
        DataTypes.SettlementType moduleId,
        address module
    ) external auth {
        settlementModule[moduleId] = module;
        emit SystemSetSettlementModule(moduleId, module);
    }

    /**
     * @notice 设置支持的用于支付的代币
     * @param currency 代币合约地址
     * @param result 加入或撤出白名单
     * Fn 3
     */
    function setWhitelistedCurrency(
        address currency,
        bool result
    ) external auth {
        whitelistCurrency[currency] = result;
        emit SystemSetCurrencyIsWhitelisted(currency, result);
    }

    /**
     * @notice 设置支持的守护合约
     * @param guard 守护模块合约地址
     * @param result 加入或撤出白名单
     * Fn 4
     */
    function setWhitelistedGuardModule(
        address guard,
        bool result
    ) external auth {
        whitelistGuardModule[guard] = result;
        emit SystemSetGuardModuleIsWhitelisted(guard, result);
    }

    /**
     * @notice 设置支持的审核合约
     * @param module 审核模块合约地址
     * @param result 加入或撤出白名单
     * Fn 5
     */
    function setWhitelistedAuditModule(
        address module,
        bool result
    ) external auth {
        whitelistAuditModule[module] = result;
        emit SystemSetAuditModuleIsWhitelisted(module, result);
    }

    /**
     * @notice 设置支持的检测合约
     * @param module 检测模块合约地址
     * @param result 加入或撤出白名单
     * Fn 6
     */
    function setDetectionModuleIsWhitelisted(
        address module,
        bool result
    ) external auth {
        whitelistDetectionModule[module] = result;
        emit SystemSetDetectionModuleIsWhitelisted(module, result);
    }

    // ***************** View Functions *****************
    function isAuditModuleWhitelisted(
        address module
    ) external view returns (bool) {
        return whitelistAuditModule[module];
    }

    function isDetectionModuleWhitelisted(
        address module
    ) external view returns (bool) {
        return whitelistDetectionModule[module];
    }

    function isGuardModuleWhitelisted(
        address module
    ) external view returns (bool) {
        return whitelistGuardModule[module];
    }

    function isCurrencyWhitelisted(
        address currency
    ) external view returns (bool) {
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

    function getSettlementModuleAddress(
        DataTypes.SettlementType moduleId
    ) external view returns (address) {
        return settlementModule[moduleId];
    }
}
