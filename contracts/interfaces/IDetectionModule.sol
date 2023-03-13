// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDetectionModule {
    function detectionInSubmitItem(
        uint256 taskId,
        uint256 origin
    ) external view returns (bool);

    function detectionInUpdateItem(
        uint256 newUpload,
        uint256 oldUpload
    ) external view returns (bool);

    function distanceThreshold() external view returns (uint256);
}
