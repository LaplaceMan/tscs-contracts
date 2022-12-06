// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMurmes {
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

    // ***** StrategyManager *****
    function auditStrategy() external view returns (address);

    function accessStrategy() external view returns (address);

    function detectionStrategy() external view returns (address);

    function lockUpTime() external view returns (uint256);

    function getSettlementStrategyBaseInfo(uint8 strategyId)
        external
        view
        returns (address, string memory);

    // ***** SubtitleManager *****
    function subtitleToken() external returns (address);

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
}
