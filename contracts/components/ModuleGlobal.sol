// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IModuleGlobal.sol";
import {Events} from "../libraries/Events.sol";

interface MurmesInterface {
    function owner() external view returns (address);

    function setOperatorByTool(address old, address replace) external;
}

contract ModuleGlobal is IModuleGlobal {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 记录白名单内的审核（Item状态改变）模块合约地址
     */
    mapping(address => bool) whitelistAuditModule;
    /**
     * @notice 记录白名单内的个人守护模块合约地址
     */
    mapping(address => bool) whitelistGuardModule;
    /**
     * @notice 记录白名单内的Item检测模块合约地址
     */
    mapping(address => bool) whitelistDetectionModule;
    /**
     * @notice 记录白名单内的特殊权限模块合约地址
     */
    mapping(address => bool) whitelistAuthorityModule;
    /**
     * @notice 记录不同结算策略的模块合约地址
     */
    mapping(DataTypes.SettlementType => address) settlementModule;
    /**
     * @notice 记录白名单内的代币合约地址
     */
    mapping(address => bool) whitelistCurrency;

    constructor(address ms) {
        Murmes = ms;
        whitelistCurrency[address(0)] = true;
    }

    // Fn 1
    modifier auth() {
        require(MurmesInterface(Murmes).owner() == msg.sender, "M15");
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
        MurmesInterface(Murmes).setOperatorByTool(
            settlementModule[moduleId],
            module
        );
        settlementModule[moduleId] = module;
        emit Events.MurmesSetSettlementModule(moduleId, module);
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
        emit Events.MurmesSetCurrencyIsWhitelisted(currency, result);
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
        emit Events.MurmesSetGuardModuleIsWhitelisted(guard, result);
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
        emit Events.MurmesSetAuditModuleIsWhitelisted(module, result);
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
        emit Events.MurmesSetDetectionModuleIsWhitelisted(module, result);
    }

    /**
     * @notice 设置支持的平台权限控制模块
     * @param module 权限控制模块合约地址
     * @param result 加入或撤出白名单
     * Fn 7
     */
    function setAuthorityModuleIsWhitelisted(
        address module,
        bool result
    ) external auth {
        whitelistAuthorityModule[module] = result;
        emit Events.MurmesSetAuthorityModuleIsWhitelisted(module, result);
    }

    // ***************** View Functions *****************
    function isAuditModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistAuditModule[module];
    }

    function isDetectionModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistDetectionModule[module];
    }

    function isGuardModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistGuardModule[module];
    }

    function isAuthorityModuleWhitelisted(
        address module
    ) external view override returns (bool) {
        return whitelistAuthorityModule[module];
    }

    function isCurrencyWhitelisted(
        address currency
    ) external view override returns (bool) {
        return whitelistCurrency[currency];
    }

    function isPostTaskModuleValid(
        address currency,
        address audit,
        address detection
    ) external view override returns (bool) {
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
    ) external view override returns (address) {
        return settlementModule[moduleId];
    }
}
