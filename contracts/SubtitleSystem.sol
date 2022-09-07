// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./base/PlatformManager.sol";
import "./base/SubtitleManager.sol";
import "./base/VideoManager.sol";

contract SubtitleSystem is PlatformManager, SubtitleManager, VideoManager {
    uint256 public totalApplyNumber;

    struct Application {
        address applicant;
        uint256 videoId;
        uint8 mode;
        uint256 number;
        uint16 language;
        uint256[] subtitles;
        uint256 adopted;
        uint256 totalUsageCounts;
        uint256 settledUsageCouts;
    }

    mapping(uint256 => Application) totalApplys;

    function submitApplication(
        address platform,
        uint256 videoId,
        uint8 mode,
        uint256 number,
        uint16 language
    ) external {
        totalApplyNumber++;
        if (platform == address(0)) {
            require(mode == 1, "GAM Only One-time");
        }
        totalApplys[totalApplyNumber].videoId = videoId;
        totalApplys[totalApplyNumber].mode = mode;
        totalApplys[totalApplyNumber].number = number;
        totalApplys[totalApplyNumber].language = language;
    }

    function uploadSubtitle(
        uint256 applyId,
        uint16 languageId,
        string memory fingerprint
    ) external {
        uint256 subtitleId = _createST(
            msg.sender,
            applyId,
            languageId,
            fingerprint
        );
        require(totalApplys[applyId].adopted == 0, "Finished");
        totalApplys[applyId].subtitles.push(subtitleId);
    }
}
