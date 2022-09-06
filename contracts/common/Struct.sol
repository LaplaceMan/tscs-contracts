// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Struct {
    struct Application {
        address applicant;
        uint256 time;
        uint8 mode;
        uint256 number;
        string language;
        uint256[] subtitles;
        uint256 adopted;
        uint256 totalUsageCounts;
        uint256 latestUpdateTime;
        uint256 settledUsageCouts;
        uint256 latestSettleTime;
    }
}
