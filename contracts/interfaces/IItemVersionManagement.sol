// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct version {
    string source;
    uint256 fingerprint;
    bool invalid;
}

interface IItemVersionManagement {
    function reportInvalidVersion(uint256 itemId, uint256 versionId) external;

    function getSpecifyVersion(
        uint256 itemId,
        uint256 versionId
    ) external view returns (version memory);

    function getVersionNumebr(
        uint256 itemId
    ) external view returns (uint256, uint256);

    function getLatestValidVersion(
        uint256 itemId
    ) external view returns (string memory, uint256);
}
