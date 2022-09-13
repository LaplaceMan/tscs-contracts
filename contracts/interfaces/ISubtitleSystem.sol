// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISubtitleSystem {
    function preDivide(
        address platform,
        address to,
        uint256 amount
    ) external;

    function preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) external;

    function penalty() external view returns (uint256);

    function zimuToken() external view returns (address);

    function videoToken() external view returns (address);

    function languageTypes() external view returns (uint16);

    function totalPlatforms() external view returns (uint256);

    function auditStrategy() external view returns (address);

    function accessStrategy() external view returns (address);

    function detectionStrategy() external view returns (address);

    function totalVideoNumber() external view returns (uint256);
}
