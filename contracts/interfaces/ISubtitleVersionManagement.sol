// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISubtitleVersionManagement {
    function reportInvalidVersion(uint256 subtitleId, uint256 versionId)
        external;
}
