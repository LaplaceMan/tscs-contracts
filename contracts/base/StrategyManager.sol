// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PlatformManager.sol";
import "../interfaces/IAccessStrategy.sol";
import "../interfaces/IAuditStrategy.sol";
import "../interfaces/IDetectionStrategy.sol";

contract StrategyManager is PlatformManager {
    IAuditStrategy public auditStrategy;
    IAccessStrategy public accessStrategy;
    IDetectionStrategy public detectionStrategy;

    function setDefaultAuditStrategy(IAuditStrategy newAudit) external auth {
        auditStrategy = newAudit;
    }

    function setDefaultAccessStrategy(IAccessStrategy newAccess) external auth {
        accessStrategy = newAccess;
    }

    function setDefaultDetectionStrategy(IDetectionStrategy newDetection)
        external
        auth
    {
        detectionStrategy = newDetection;
    }
}
