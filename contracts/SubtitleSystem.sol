// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISettlementStrategy.sol";
import "./base/StrategyManager.sol";
import "./base/SubtitleManager.sol";
import "./base/VideoManager.sol";
import "./interfaces/IVT.sol";

contract SubtitleSystem is StrategyManager, SubtitleManager, VideoManager {
    uint256 public totalApplyNumber;
    uint16 constant RATE_BASE = 65535;
    struct Application {
        address applicant;
        uint256 videoId;
        uint8 mode;
        uint256 amount;
        uint16 language;
        uint256[] subtitles;
        uint256 adopted;
        uint256 unsettled;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    mapping(uint256 => Application) totalApplys;

    function createVideo(
        address platform,
        uint256 id,
        string memory symbol,
        address creator,
        uint256 total
    ) external returns (uint256) {
        require(
            platform != address(0) &&
                platforms[platform].rateCountsToProfit > 0,
            "Platform Invaild"
        );
        uint256 videoId = _createVideo(platform, id, symbol, creator, total);
        return videoId;
    }

    function submitApplication(
        address platform,
        uint256 videoId,
        uint8 mode,
        uint256 amount,
        uint16 language
    ) external {
        _userInitialization(msg.sender, 0);
        require(
            accessStrategy.access(
                users[msg.sender].repution,
                users[msg.sender].deposit
            ),
            "Not Qualified"
        );
        totalApplyNumber++;
        if (platform == address(0)) {
            require(mode == 0, "GAM Only One-time");
            IVT(videoToken).divide(
                platforms[platform].platformId,
                msg.sender,
                address(this),
                amount
            );
            ISettlementStrategy(settlementStrategy[0].strategy)
                .updateDebtOrReward(totalApplyNumber, amount);
        } else {
            require(videos[videoId].creator == msg.sender, "No Permission");
            for (uint256 i; i < videos[videoId].applys.length; i++) {
                uint256 applyId = videos[videoId].applys[i];
                require(
                    totalApplys[applyId].language != language,
                    "Already Applied"
                );
            }
        }
        totalApplys[totalApplyNumber].videoId = videoId;
        totalApplys[totalApplyNumber].mode = mode;
        totalApplys[totalApplyNumber].amount = amount;
        totalApplys[totalApplyNumber].language = language;
    }

    function _getHistoryFingerprint(uint256 applyId)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory history = new uint256[](
            totalApplys[applyId].subtitles.length
        );
        for (uint256 i = 0; i < totalApplys[applyId].subtitles.length; i++) {
            history[i] = subtitleNFT[totalApplys[applyId].subtitles[i]]
                .fingerprint;
        }
        return history;
    }

    function uploadSubtitle(
        uint256 applyId,
        uint16 languageId,
        uint256 fingerprint
    ) external {
        require(
            languageId == totalApplys[applyId].language,
            "Language Inconsistency"
        );
        _userInitialization(msg.sender, 0);
        require(
            accessStrategy.access(
                users[msg.sender].repution,
                users[msg.sender].deposit
            ),
            "Not Qualified"
        );
        uint256[] memory history = _getHistoryFingerprint(applyId);
        require(
            detectionStrategy.detection(fingerprint, history),
            "High Similarity"
        );
        uint256 subtitleId = _createST(
            msg.sender,
            applyId,
            languageId,
            fingerprint
        );
        require(totalApplys[applyId].adopted == 0, "Finished");
        totalApplys[applyId].subtitles.push(subtitleId);
    }

    function updateUsageCounts(uint256[] memory id, uint256[] memory ss)
        external
    {
        assert(id.length == ss.length);
        for (uint256 i = 0; i < id.length; i++) {
            if (totalApplys[i].adopted > 0) {
                address platform = videos[totalApplys[id[i]].videoId].platform;
                require(msg.sender == platform, "No Permission");
                require(totalApplys[id[i]].mode != 0, "Invaild Mode");
                uint256 unpaidToken = (platforms[platform].rateCountsToProfit *
                    ss[i]) / RATE_BASE;
                ISettlementStrategy(
                    settlementStrategy[totalApplys[id[i]].mode].strategy
                ).updateDebtOrReward(id[i], unpaidToken);
            }
        }
    }

    function _getSubtitleAuditInfo(uint256 subtitleId)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 applyId = subtitleNFT[subtitleId].applyId;
        uint256 uploaded = totalApplys[applyId].subtitles.length;
        uint256 allSupport;
        for (uint256 i = 0; i < uploaded; i++) {
            uint256 singleSubtitle = totalApplys[applyId].subtitles[i];
            allSupport += subtitleNFT[singleSubtitle].supporters.length;
        }
        return (
            uploaded,
            subtitleNFT[subtitleId].supporters.length,
            subtitleNFT[subtitleId].dissenter.length,
            allSupport
        );
    }

    function _updateUsers(
        uint256 subtitleId,
        uint8 flag,
        uint256 reputionSpread,
        uint256 tokenSpread,
        uint8 multiplier
    ) internal {
        int8 newFlag = 1;
        if (flag == 2) newFlag = -1;
        _updateUser(
            ownerOf(subtitleId),
            int256((reputionSpread * multiplier) / 100) * newFlag,
            int256((tokenSpread * multiplier) / 100) * newFlag
        );
        for (
            uint256 i = 0;
            i < subtitleNFT[subtitleId].supporters.length;
            i++
        ) {
            _updateUser(
                subtitleNFT[subtitleId].supporters[i],
                int256(reputionSpread) * newFlag,
                int256(tokenSpread) * newFlag
            );
        }
        for (uint256 i = 0; i < subtitleNFT[subtitleId].dissenter.length; i++) {
            _updateUser(
                subtitleNFT[subtitleId].dissenter[i],
                int256(reputionSpread) * newFlag,
                int256(tokenSpread) * newFlag
            );
        }
    }

    function evaluateSubtitle(uint256 subtitleId, uint8 attitude) external {
        _userInitialization(msg.sender, 0);
        require(
            accessStrategy.access(
                users[msg.sender].repution,
                users[msg.sender].deposit
            ),
            "Not Qualified"
        );
        _evaluateST(subtitleId, attitude, msg.sender);
        (
            uint256 uploaded,
            uint256 support,
            uint256 against,
            uint256 allSupport
        ) = _getSubtitleAuditInfo(subtitleId);
        uint8 flag = auditStrategy.auditResult(
            uploaded,
            support,
            against,
            allSupport
        );
        if (flag != 0) {
            _changeST(subtitleId, flag);
            (
                uint256 reputionSpread,
                uint256 tokenSpread,
                uint8 multiplier
            ) = accessStrategy.spread(users[msg.sender].repution, flag);
            _updateUsers(
                subtitleId,
                flag,
                reputionSpread,
                tokenSpread,
                multiplier
            );
        }
    }

    function preExtractMode0(uint256 applyId) external {
        require(totalApplys[applyId].mode == 0, "Not Applicable");
        address platform = videos[totalApplys[applyId].videoId].platform;
        ISettlementStrategy(settlementStrategy[0].strategy).settlement(
            applyId,
            platform,
            ownerOf(totalApplys[applyId].adopted),
            address(0),
            totalApplys[applyId].amount,
            platforms[platform].rateCountsToProfit,
            platforms[platform].rateAuditorDivide,
            subtitleNFT[totalApplys[applyId].adopted].supporters
        );
    }

    //仍需优化, 实现真正的模块化
    //结算mode拥有优先度, 根据id(序号)划分
    function preExtract(uint256 videoId) external {
        require(videos[videoId].unsettled > 0, "Invalid Settlement");
        uint256 unsettled = (platforms[videos[videoId].platform]
            .rateCountsToProfit * videos[videoId].unsettled) / RATE_BASE;
        for (uint256 i = 0; i < videos[videoId].applys.length; i++) {
            uint256 applyId = videos[videoId].applys[i];
            if (
                totalApplys[applyId].adopted > 0 &&
                totalApplys[applyId].mode == 1 &&
                unsettled > 0
            ) {
                uint256 subtitleGet = ISettlementStrategy(
                    settlementStrategy[1].strategy
                ).settlement(
                        applyId,
                        videos[videoId].platform,
                        ownerOf(totalApplys[applyId].adopted),
                        videos[videoId].creator,
                        totalApplys[applyId].amount,
                        platforms[videos[videoId].platform].rateCountsToProfit,
                        platforms[videos[videoId].platform].rateAuditorDivide,
                        subtitleNFT[totalApplys[applyId].adopted].supporters
                    );
                unsettled -= subtitleGet;
            }
        }

        for (uint256 i = 0; i < videos[videoId].applys.length; i++) {
            uint256 applyId = videos[videoId].applys[i];
            if (
                totalApplys[applyId].adopted > 0 &&
                totalApplys[applyId].mode == 2 &&
                unsettled > 0
            ) {
                uint256 subtitleGet = ISettlementStrategy(
                    settlementStrategy[2].strategy
                ).settlement(
                        applyId,
                        videos[videoId].platform,
                        ownerOf(totalApplys[applyId].adopted),
                        videos[videoId].creator,
                        totalApplys[applyId].amount,
                        platforms[videos[videoId].platform].rateCountsToProfit,
                        platforms[videos[videoId].platform].rateAuditorDivide,
                        subtitleNFT[totalApplys[applyId].adopted].supporters
                    );
                unsettled -= subtitleGet;
            }
        }

        if (unsettled > 0) {
            IVT(videoToken).mintStableToken(
                platforms[videos[videoId].platform].platformId,
                videos[videoId].creator,
                unsettled
            );
        }

        videos[videoId].unsettled = 0;
    }

    function setZimuToken(address token) external auth {
        zimuToken = token;
    }

    function setVideoToken(address token) external auth {
        videoToken = token;
    }

    function preDivide(
        address platform,
        address to,
        uint256 amount
    ) external auth {
        _preDivide(platform, to, amount);
    }

    function preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) external auth {
        _preDivideBatch(platform, to, amount);
    }
}
