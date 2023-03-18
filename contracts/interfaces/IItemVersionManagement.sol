// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IItemVersionManagement {
    function updateItemVersion(
        uint256 itemId,
        uint256 fingerprint,
        string memory source
    ) external returns (uint256);

    function reportInvalidVersion(uint256 itemId, uint256 versionId) external;

    function getSpecifyVersion(
        uint256 itemId,
        uint256 versionId
    ) external view returns (DataTypes.VersionStruct memory);

    function getAllVersion(
        uint256 itemId
    ) external view returns (uint256, uint256);

    function getLatestValidVersion(
        uint256 itemId
    ) external view returns (string memory, uint256);

    event ReportInvalidVersion(uint256 itemId, uint256 versionId);

    event UpdateItemVersion(
        uint256 itemId,
        uint256 fingerprint,
        string source,
        uint256 versionId
    );
}
