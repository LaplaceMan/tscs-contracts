/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-07 17:56:09
 * @Description: 基于区块链的代币化字幕众包系统
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISettlementStrategy.sol";
import "./base/StrategyManager.sol";
import "./base/SubtitleManager.sol";
import "./base/VideoManager.sol";
import "./interfaces/IVT.sol";

contract SubtitleSystem is StrategyManager, SubtitleManager, VideoManager {
    /**
     * @notice TSCS 内已经发出的申请总数
     */
    uint256 public totalApplyNumber;
    /**
     * @notice 结算相关时的除数
     */
    uint16 constant RATE_BASE = 65535;
    /**
     * @notice 锁定期（审核期）
     */
    uint256 public lockUpTime;

    /**
     * @notice 每个申请都有一个相应的 Application 结构记录申请信息
     * @param applicant 发出申请, 需求制作字幕服务的用户
     * @param videoId 申请所属视频的 ID
     * @param mode 结算策略
     * @param amount 支付金额/比例
     * @param language 申请所需语言的 ID
     * @param subtitles 申请下已上传字幕的 ID 集合
     * @param adopted 最终被采纳字幕的 ID
     */
    struct Application {
        address applicant;
        uint256 videoId;
        uint8 mode;
        uint256 amount;
        uint16 language;
        uint256[] subtitles;
        uint256 adopted;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @notice applyId 与 Application 的映射, 从 1 开始（发出申请的顺位）
     */
    mapping(uint256 => Application) totalApplys;

    /**
     * @notice 由平台 Platform 注册视频, 此后该视频支持链上结算（意味着更多结算策略的支持）
     * @param platform 平台 Platform 区块链地址
     * @param id 视频在 Platform 内部的 ID
     * @param symbol 视频的 symbol
     * @param creator 视频创作者区块链地址
     * @param total 视频当前的总播放量（已结算）
     * @return 视频在 TSCS 内的 ID
     */
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

    /**
     * @notice 提交制作字幕的申请
     * @param platform 视频所属平台 Platform 区块链地址
     * @param videoId 视频在 TSCS 内的 ID
     * @param mode 结算策略 ID
     * @param amount 支付金额/比例
     * @param language 申请所需要语言的 ID
     * @return 在 TSCS 内发出申请的顺位, applyId
     */
    function submitApplication(
        address platform,
        uint256 videoId,
        uint8 mode,
        uint256 amount,
        uint16 language
    ) external returns (uint256) {
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 ETH 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].repution,
                users[msg.sender].deposit
            ),
            "Not Qualified"
        );
        totalApplyNumber++;
        // 当平台地址为 0, 意味着使用默认结算策略
        if (platform == address(0)) {
            require(mode == 0, "GAM Only One-time");
            // 一次性结算策略下, 使用先销毁申请人奖励代币, 后给字幕制作者和支持者铸造代币的方案
            IVT(videoToken).burnStableToken(
                platforms[platform].platformId,
                msg.sender,
                amount
            );
            // 更新未结算稳定币数目
            ISettlementStrategy(settlementStrategy[0].strategy)
                .updateDebtOrReward(totalApplyNumber, amount);
        } else {
            // 当结算策略非一次性时, 与视频收益相关, 需要由视频创作者主动提起
            require(videos[videoId].creator == msg.sender, "No Permission");
            // 下面是为了防止重复申请制作同一语言的字幕
            for (uint256 i; i < videos[videoId].applys.length; i++) {
                uint256 applyId = videos[videoId].applys[i];
                require(
                    totalApplys[applyId].language != language,
                    "Already Applied"
                );
            }
        }
        totalApplys[totalApplyNumber].applicant = msg.sender;
        totalApplys[totalApplyNumber].videoId = videoId;
        totalApplys[totalApplyNumber].mode = mode;
        totalApplys[totalApplyNumber].amount = amount;
        totalApplys[totalApplyNumber].language = language;
        return totalApplyNumber;
    }

    /**
     * @notice 获得特定申请下所有已上传字幕的指纹, 暂定为 Simhash
     * @param applyId 申请在 TSCS 内的顺位 ID
     * @return 该申请下所有已上传字幕的 fingerprint
     */
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

    /**
     * @notice 上传制作的字幕
     * @param applyId 字幕所属申请在 TSCS 内的顺位 ID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹值, 暂定为 Simhash
     * @return 字幕 ST ID
     */
    function uploadSubtitle(
        uint256 applyId,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256) {
        // 确保字幕的语言与申请所需的语言一致
        require(
            languageId == totalApplys[applyId].language,
            "Language Inconsistency"
        );
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 ETH 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].repution,
                users[msg.sender].deposit
            ),
            "Not Qualified"
        );
        uint256[] memory history = _getHistoryFingerprint(applyId);
        // 字幕相似度检测
        require(
            detectionStrategy.beforeDetection(fingerprint, history),
            "High Similarity"
        );
        // ERC721 Token 生成
        uint256 subtitleId = _createST(
            msg.sender,
            applyId,
            languageId,
            fingerprint
        );
        // 无法为已被确认的申请上传字幕, 防止资金和制作力浪费
        require(totalApplys[applyId].adopted == 0, "Finished");
        totalApplys[applyId].subtitles.push(subtitleId);
        return subtitleId;
    }

    /**
     * @notice 由平台 Platform 更新其旗下视频中被确认字幕的使用量
     * @param id 相应的申请 ID
     * @param ss 新增使用量
     */
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

    /**
     * @notice 获得特定字幕与审核相关的信息
     * @param subtitleId 字幕 ID
     * @return 同一申请下已上传字幕数, 该字幕获得的支持数, 该字幕获得的反对数, 同一申请下已上传字幕获得支持数的和
     */
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

    /**
     * @notice 批量更新用户信誉度和质押信息, 字幕状态发生变化时被调用
     * @param subtitleId 字幕 ID
     * @param flag 1 表示字幕被采用（奖励）, 2 表示字幕被认定为恶意字幕（惩罚）
     * @param reputionSpread 信誉度变化值
     * @param tokenSpread ETH 变化值
     * @param multiplier 字幕制作者受到的奖励/惩罚倍数
     */
    function _updateUsers(
        uint256 subtitleId,
        uint8 flag,
        uint256 reputionSpread,
        uint256 tokenSpread,
        uint8 multiplier
    ) internal {
        int8 newFlag = 1;
        // 2 表示字幕被认定为恶意字幕, 对字幕制作者和支持者进行惩罚, 所以标志位为 负
        if (flag == 2) newFlag = -1;
        // 更新字幕制作者信誉度和 ETH 质押数信息
        _updateUser(
            ownerOf(subtitleId),
            int256((reputionSpread * multiplier) / 100) * newFlag,
            int256((tokenSpread * multiplier) / 100) * newFlag
        );
        // 更新审核员信息, 支持者和反对者受到的待遇相反
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
                int256(reputionSpread) * newFlag * (-1),
                int256(tokenSpread) * newFlag * (-1)
            );
        }
    }

    /**
     * @notice 评价/审核字幕
     * @param subtitleId 字幕 ST ID
     * @param attitude 态度, 0 表示积极/支持, 1 表示消极/反对
     */
    function evaluateSubtitle(uint256 subtitleId, uint8 attitude) external {
        // 若调用者未主动加入 TSCS, 则自动初始化用户的信誉度和质押数（质押数自动设置为 0）
        _userInitialization(msg.sender, 0);
        // 根据信誉度和质押 ETH 数判断用户是否有权限使用 TSCS 提供的服务
        require(
            accessStrategy.access(
                users[msg.sender].repution,
                users[msg.sender].deposit
            ),
            "Not Qualified"
        );
        _evaluateST(subtitleId, attitude, msg.sender);
        // 基于字幕审核信息和审核策略判断字幕状态改变
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
            // 改变 ST 状态, 以及利益相关者信誉度和质押 ETH 信息
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
            // 字幕被采用, 更新相应申请的状态
            if (flag == 1) {
                totalApplys[subtitleNFT[subtitleId].applyId]
                    .adopted = subtitleId;
            }
        }
    }

    /**
     * @notice 预结算（视频和字幕）收益, 此处仅适用于结算策略为一次性结算（0）的申请
     * @param applyId 申请 ID
     */
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

    /**
     * @notice 预结算（视频和字幕）收益, 仍需优化, 实现真正的模块化
     * @param videoId 视频在 TSCS 内的 ID
     * @return 本次结算稳定币数目
     */
    function preExtract(uint256 videoId) external returns (uint256) {
        require(videos[videoId].unsettled > 0, "Invalid Settlement");
        // 获得相应的代币计价
        uint256 unsettled = (platforms[videos[videoId].platform]
            .rateCountsToProfit * videos[videoId].unsettled) / RATE_BASE;
        // 结算策略 mode 拥有优先度, 根据id（小的优先级高）划分
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
        // 若支付完字幕制作费用后仍有剩余, 则直接将收益以稳定币的形式发送给视频创作者
        if (unsettled > 0) {
            IVT(videoToken).mintStableToken(
                platforms[videos[videoId].platform].platformId,
                videos[videoId].creator,
                unsettled
            );
        }

        videos[videoId].unsettled = 0;
        return unsettled;
    }

    /**
     * @notice 设置/修改平台币合约地址
     * @param token 新的 ERC20 TSCS 平台币合约地址
     */
    function setZimuToken(address token) external auth {
        zimuToken = token;
    }

    /**
     * @notice 设置/修改稳定币合约地址
     * @param token 新的 ERC1155 稳定币合约地址
     */
    function setVideoToken(address token) external auth {
        videoToken = token;
    }

    /**
     * @notice 设置/修改锁定期（审核期）
     * @param time 新的锁定时间（审核期）
     */
    function setLockUp(uint256 time) external auth {
        require(time > 0, "Invaild Lock Time");
        lockUpTime = time;
    }

    /**
     * @notice 预结算（字幕制作者）收益, "预" 指的是结算后不会直接得到稳定币, 经过锁定期（审核期）后才能提取
     * @param platform 所属平台 Platform 区块链地址
     * @param to 收益接收方
     * @param amount 新增数目
     */
    function preDivide(
        address platform,
        address to,
        uint256 amount
    ) external auth {
        _preDivide(platform, to, amount);
    }

    /**
     * @notice 为批量用户（字幕支持者）预结算收益, "预" 指的是结算后不会直接得到稳定币, 经过锁定期（审核期）后才能提取
     * @param platform 所属平台 Platform 区块链地址
     * @param to 收益接收方
     * @param amount 新增数目
     */
    function preDivideBatch(
        address platform,
        address[] memory to,
        uint256 amount
    ) external auth {
        _preDivideBatch(platform, to, amount);
    }

    /**
     * @notice 提取经过锁定期的收益
     * @param platform 要提取的平台 Platform 的区块链地址
     * @param day 要提取 天 的集合
     * @return 本次总共提取的（由相应平台背书的）稳定币数
     */
    function withdraw(address platform, uint256[] memory day)
        external
        returns (uint256)
    {
        uint256 all;
        for (uint256 i = 0; i < day.length; i++) {
            if (
                users[msg.sender].lock[platform][day[i]] > 0 &&
                block.timestamp >= day[i] + lockUpTime
            ) {
                all += users[msg.sender].lock[platform][day[i]];
                users[msg.sender].lock[platform][day[i]] = 0;
            }
        }
        if (all > 0) {
            IVT(videoToken).mintStableToken(
                platforms[platform].platformId,
                msg.sender,
                all
            );
        }
        return all;
    }
}
