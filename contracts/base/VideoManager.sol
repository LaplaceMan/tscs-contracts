// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VideoManager {
    uint256 totalVideoNumber;
    mapping(uint256 => Video) videos;
    mapping(address => mapping(uint256 => uint256)) idReal2System;

    struct Video {
        address platform;
        uint256 id;
        string symbol;
        address creator;
        uint256 tatalViewCouts;
        uint256[] applys;
    }

    function _createVideo(
        address platform,
        uint256 id,
        string memory symbol,
        address creator,
        uint256 total
    ) internal {
        totalVideoNumber++;
        require(idReal2System[msg.sender][id] == 0, "Video Have Created");
        videos[totalVideoNumber].platform = platform;
        videos[totalVideoNumber].id = id;
        videos[totalVideoNumber].symbol = symbol;
        videos[totalVideoNumber].creator = creator;
        videos[totalVideoNumber].tatalViewCouts = total;
        idReal2System[msg.sender][id] = totalVideoNumber;
    }

    function _updateViewCounts(uint256[] memory id, uint256[] memory vs)
        internal
    {
        assert(id.length == vs.length);

        for (uint256 i = 0; i < id.length; i++) {
            videos[i].tatalViewCouts += vs[i];
        }
    }

    // function updateUsageCounts(uint256[] memory id, uint256[] memory ss)
    //     external
    // {
    //     assert(id.length == ss.length);
    //     for (uint256 i = 0; i < id.length; i++) {
    //         if (totalApplys[i].adopted > 0) {
    //             totalApplys[i].totalUsageCounts += ss[i];
    //         }
    //     }
    // }
}
