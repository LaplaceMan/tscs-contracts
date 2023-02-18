// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPlatform {
    // ***** VideoManager *****
    function totalVideos() external view returns (uint256);

    function updateViewCounts(uint256[] memory id, uint256[] memory vs)
        external;

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

    function getVideoOrderIdByRealId(address platfrom, uint256 realId)
        external
        view
        returns (uint256);

    // ***** Platforms ****
    function totalPlatforms() external view returns (uint256);

    function tokenGlobal() external view returns (address);

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

    function getPlatformIdByAddress(address platform)
        external
        view
        returns (uint256);

    function platformRate(uint16 rate1, uint16 rate2)
        external
        returns (uint16, uint16);

    function createVideo(
        uint256 id,
        string memory symbol,
        address creator,
        uint256 initialize,
        address from
    ) external returns (uint256);

    function updateVideoTasks(uint256 videoId, uint256[] memory tasks) external;

    function updateVideoUnsettled(uint256 videoId, int256 differ) external;

    function setMurmesAuditorDivideRate(uint16 auditorDivide) external;
}
