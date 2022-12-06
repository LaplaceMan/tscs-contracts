// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDetectionStrategy {
    function opeator() external view returns (address);

    function beforeDetection(uint256 origin, uint256[] memory history)
        external
        view
        returns (bool);

    function afterDetection(uint256 newUpload, uint256 oldUpload)
        external
        view
        returns (bool);

    function distanceThreshold() external view returns (uint8);
}
