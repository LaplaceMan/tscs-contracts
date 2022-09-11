// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PlatformManager.sol";
import "../interfaces/IAccessStrategy.sol";
import "../interfaces/IAuditStrategy.sol";
import "../interfaces/IDetectionStrategy.sol";
import "../interfaces/ISettlementStrategy.sol";

contract StrategyManager is PlatformManager {
    IAuditStrategy public auditStrategy;
    IAccessStrategy public accessStrategy;
    IDetectionStrategy public detectionStrategy;

    struct SettlementStruct {
        address strategy;
        string notes;
    }

    mapping(uint8 => SettlementStruct) settlementStrategy;

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

    function setSettlementStrategy(
        uint8 strategyId,
        address strategy,
        string memory notes
    ) external auth {
        settlementStrategy[strategyId].strategy = strategy;
        settlementStrategy[strategyId].notes = notes;
    }
}
