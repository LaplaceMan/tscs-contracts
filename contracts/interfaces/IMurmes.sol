// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMurmes {
    // ***** Ownable *****
    function isOperator(address operator) external view returns (bool);

    function owner() external view returns (address);

    function multiSig() external view returns (address);

    // ***** EntityManager *****
    function zimuToken() external view returns (address);

    function videoToken() external view returns (address);

    function vault() external view returns (address);

    function platforms() external view returns (address);

    function fee() external view returns (uint16);

    function despoit() external view returns (uint256);

    function getLanguageNoteById(uint16 languageId)
        external
        view
        returns (string memory);

    function getLanguageIdByNote(string memory note)
        external
        view
        returns (uint16);

    function getUserBaseInfo(address usr)
        external
        view
        returns (uint256, int256);

    function getUserLockReward(
        address usr,
        address platform,
        uint256 day
    ) external view returns (uint256);

    function gutUserGuard(address usr) external view returns (address);

    function updateUser(
        address usr,
        int256 reputationSpread,
        int256 tokenSpread
    ) external;

    // ***** StrategyManager *****
    function auditStrategy() external view returns (address);

    function accessStrategy() external view returns (address);

    function detectionStrategy() external view returns (address);

    function lockUpTime() external view returns (uint256);

    function getSettlementStrategyBaseInfo(uint8 strategyId)
        external
        view
        returns (address, string memory);

    function holdSubtitleStateByDAO(uint256 id, uint8 state) external;

    // ***** SubtitleManager *****
    function subtitleToken() external returns (address);

    function versionManagement() external returns (address);

    function getSubtitleBaseInfo(uint256 subtitleId)
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            address[] memory,
            address[] memory
        );

    // ***** Murmes *****
    function totalTasks() external view returns (uint256);

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

    function updateLockReward(
        address platform,
        uint256 day,
        int256 amount,
        address usr
    ) external;

    function resetApplication(uint256 taskId, uint256 amount) external;

    function getPlatformByTaskId(uint256 taskId)
        external
        view
        returns (address);

    function submitApplication(
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint32 language,
        uint256 deadline,
        string memory source
    ) external returns (uint256);

    function uploadSubtitle(
        uint256 taskId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256);

    function cancel(uint256 taskId) external;

    function updateApplication(
        uint256 taskId,
        uint256 plusAmount,
        uint256 plusTime
    ) external;

    function tasks(uint256 taskId)
        external
        returns (
            address,
            address,
            uint256,
            string memory,
            uint8,
            uint256,
            uint32,
            uint256[] memory,
            uint256,
            uint256
        );
}
