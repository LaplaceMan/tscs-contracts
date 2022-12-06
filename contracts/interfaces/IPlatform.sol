// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlatform {
    function totalVideos() external view returns (uint256);

    function totalPlatforms() external view returns (uint256);

    function getPlatformBaseInfo(address platform)
        external
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint16,
            uint16
        );

    function getVideoBaseInfo(uint256 videoId)
        external
        view
        returns (
            address,
            uint256,
            string memory,
            address,
            uint256,
            uint256,
            uint256[] memory
        );

    function updateVideoTasks(uint256 videoId, uint256[] memory tasks) external;

    function updateVideoUnsettled(uint256 videoId, int256 differ) external;

    function setMurmesAuditorDivideRate(uint16 auditorDivide) external;
}
