// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ModuleGlobalInterface {
    function setWhitelistedCurrency(address currency, bool result) external;

    function setWhitelistedGuardModule(address guard, bool result) external;

    function setWhitelistedAuditModule(address module, bool result) external;

    function setDetectionModuleIsWhitelisted(
        address module,
        bool result
    ) external;

    function setAuthorityModuleIsWhitelisted(
        address module,
        bool result
    ) external;
}

interface ComponentGlobalInterface {
    function setLockUpTime(uint256 time) external;
}

interface PlatformsInterface {
    function addPlatform(
        address platform,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2,
        address authority
    ) external returns (uint256);
}

interface VaultInterface {
    function setFee(uint16 newFee) external;
}

interface MurmesInterface {
    function transferOwnership(address newOwner) external;
}

interface PlatformTokenInterface {
    function updateMurmesRewardBoost(uint8 flag, uint40 amount) external;

    function updateMurmesRewardState(bool state) external;
}

contract OpenPermission {
    address private _owner;

    address constant MURMES = address(0);
    address constant MODULE = address(0);
    address constant COMPONENT = address(0);
    address constant PLATFORMS = address(0);
    address constant VAULT = address(0);
    address constant PLATFORMTOKEN = address(0);

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function setWhitelistedCurrencyByProxy(
        address currency,
        bool result
    ) external {
        ModuleGlobalInterface(MODULE).setWhitelistedCurrency(currency, result);
    }

    function setWhitelistedGuardModuleByProxy(
        address guard,
        bool result
    ) external {
        ModuleGlobalInterface(MODULE).setWhitelistedGuardModule(guard, result);
    }

    function setWhitelistedAuditModuleByProxy(
        address module,
        bool result
    ) external {
        ModuleGlobalInterface(MODULE).setWhitelistedAuditModule(module, result);
    }

    function setDetectionModuleIsWhitelistedByProxy(
        address module,
        bool result
    ) external {
        ModuleGlobalInterface(MODULE).setDetectionModuleIsWhitelisted(
            module,
            result
        );
    }

    function setAuthorityModuleIsWhitelistedByProxy(
        address module,
        bool result
    ) external {
        ModuleGlobalInterface(MODULE).setAuthorityModuleIsWhitelisted(
            module,
            result
        );
    }

    function addPlatformByProxy(
        address platform,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2,
        address authority
    ) external {
        PlatformsInterface(PLATFORMS).addPlatform(platform, name, symbol, rate1, rate2, authority);
    }
    
    function setLockUpTimeByProxy(uint256 time) external onlyOwner {
        ComponentGlobalInterface(COMPONENT).setLockUpTime(time);
    }

    function setFeeByProxy(uint16 newFee) external onlyOwner {
        VaultInterface(VAULT).setFee(newFee);
    }

    function transferOwnershipByProxy(address newOwner) external onlyOwner {
        MurmesInterface(MURMES).transferOwnership(newOwner);
    }

    function updateMurmesRewardStateByProxy(bool state) external onlyOwner {
        PlatformTokenInterface(PLATFORMTOKEN).updateMurmesRewardState(state);
    }

    function updateMurmesRewardBoostByProxy(uint8 flag, uint40 amount) external onlyOwner {
        PlatformTokenInterface(PLATFORMTOKEN).updateMurmesRewardBoost(flag, amount);
    }
}
