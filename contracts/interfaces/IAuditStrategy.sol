// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuditStrategy {
    function auditResult(
        uint256 uploaded,
        uint256 support,
        uint256 against,
        uint256 allSupport
    ) external pure returns (uint8);
}
