// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IArbitration {
    function Murmes() external view returns (address);

    function totalReports() external view returns (uint256);

    function getReport(
        uint256 reportId
    ) external view returns (DataTypes.ReportStruct memory);

    function getItemReports(
        uint256 itemId
    ) external view returns (uint256[] memory);

    function report(
        DataTypes.ReportReason reason,
        uint256 itemId,
        uint256 uintProof,
        string memory stringProof
    ) external returns (uint256);

    function uploadDAOVerificationResult(
        uint256 reportId,
        string memory resultProof,
        bool result,
        uint256[] memory params
    ) external;

    event ReportPosted(
        DataTypes.ReportReason reason,
        uint256 itemId,
        uint256 proofSubtitleId,
        string otherProof,
        address reporter
    );
}
