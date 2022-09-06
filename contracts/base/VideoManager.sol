// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Struct.sol";

contract VideoManager {
    address public platform;
    uint256 public totalVideos;
    uint256 private totalPayment;
    uint8 private flag;

    uint16 rateCountsToProfit;
    uint16 rateAuditorDivide;

    Struct.Application[] totalApplys;

    mapping(uint256 => Video) videos;

    constructor(
        address owner,
        uint16 rate1,
        uint16 rate2
    ) {
        platform = owner;
        rateCountsToProfit = rate1;
        rateAuditorDivide = rate2;
    }

    modifier onlyPlatfrom() {
        require(msg.sender == platform);
        _;
    }

    struct Video {
        string symbol;
        address creator;
        uint256 tatalViewCouts;
        uint256 latestUpdateTime;
        uint256[] applys;
    }

    function createVideo(
        uint256 id,
        string memory symbol,
        address creator,
        uint256 total
    ) external onlyPlatfrom {
        totalVideos++;
        if (id == 0 && flag == 0) {
            flag = 1;
        } else if (flag == 0) {
            flag = 2;
        }
        if (flag == 1) {
            id = totalVideos;
        } else {
            require(id > 0, "Check video ID");
        }
        require(videos[id].latestUpdateTime == 0, "Video Have Created");
        videos[id].symbol = symbol;
        videos[id].creator = creator;
        videos[id].tatalViewCouts = total;
        videos[id].latestUpdateTime = block.timestamp;
    }

    function platfromRate(uint16 rate1, uint16 rate2) external onlyPlatfrom {
        require(rate1 != 0 || rate2 != 0, "Invaild Rate");
        if (rate1 != 0) {
            rateCountsToProfit = rate1;
        }
        if (rate2 != 0) {
            rateAuditorDivide = rate2;
        }
    }

    function updateViewCounts(uint256[] memory id, uint256[] memory vs)
        external
        onlyPlatfrom
    {
        assert(id.length == vs.length);

        for (uint256 i = 0; i < id.length; i++) {
            videos[i].tatalViewCouts += vs[i];
        }
    }

    function updateUsageCounts(uint256[] memory id, uint256[] memory ss)
        external
        onlyPlatfrom
    {
        assert(id.length == ss.length);
        for (uint256 i = 0; i < id.length; i++) {
            if (totalApplys[i].adopted > 0) {
                totalApplys[i].totalUsageCounts += ss[i];
                totalApplys[i].latestUpdateTime = block.timestamp;
            }
        }
    }
}
