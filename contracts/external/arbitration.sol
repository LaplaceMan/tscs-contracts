/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-12-21 10:12:34
 * @Description: 用于处理 Murmes 的恶意行为，链下投票，链上多签执行
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IST.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IMurmes.sol";
import "../interfaces/IAccessStrategy.sol";
import "../interfaces/ISubtitleVersionManagement.sol";

contract Arbitration {
    /**
     * @notice Murmes 合约地址
     */
    address immutable Murmes;

    /**
     * @notice 举报理由
     * @param PLAGIARIZE 侵权
     * @param WRONG 恶意
     * @param MISTAKEN 误删
     * @param MISMATCH 字幕与哈希不对应
     */
    enum Reason {
        PLAGIARIZE,
        WRONG,
        MISTAKEN,
        MISMATCH
    }

    /**
     * @notice 每一个举报都会拥有相应的 reportItem 结构
     * @param reporter 举报者
     * @param reason 举报理由
     * @param subtitleId 被举报的字幕 ST ID
     * @param uintProof 证明材料，一般为被侵权的字幕 ST ID，可选
     * @param stringProof 证明材料，一般为需要补充的大量材料，可以 IPFS 的形式提交，可选
     * @param resultProof 多签提交 DAO 审核结果时同时提交的由链下摘要生成的证明信息
     * @param result 最终举报结果
     */
    struct reportItem {
        address reporter;
        Reason reason;
        uint256 subtitleId;
        uint256 uintProof;
        string stringProof;
        string resultProof;
        bool result;
    }

    /**
     * @notice 平台内产生的举报总数
     */
    uint256 numberOfReports;

    /**
     * @notice 举报 ID 与 reportItem 结构体的映射
     */
    mapping(uint256 => reportItem) reports;

    /**
     * @notice 字幕 ID 与 举报 ID （集合）的映射，防止重复举报
     */
    mapping(uint256 => uint256[]) subtitleReports;

    event NewReport(
        Reason reason,
        uint256 subtitleId,
        uint256 proofSubtitleId,
        string otherProof,
        address reporter
    );

    event ReportResult(uint256 reportId, string resultProof, bool result);

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 发起一个新的举报
     * @param reason 举报理由/原因
     * @param subtitleId 被举报字幕 ST ID
     * @param uintProof 证明材料，类型为 UINT
     * @param stringProof 证明材料，类型为 STRING
     */
    function report(
        Reason reason,
        uint256 subtitleId,
        uint256 uintProof,
        string memory stringProof
    ) public {
        {
            (uint256 reputation, int256 deposit) = IMurmes(Murmes)
                .getUserBaseInfo(msg.sender);
            address st = IMurmes(Murmes).subtitleToken();
            address access = IMurmes(Murmes).accessStrategy();
            require(IAccessStrategy(access).access(reputation, deposit), "ER5");
            require(
                deposit >= int256(IAccessStrategy(access).minDeposit()),
                "ER5-2"
            );
            require(IST(st).ownerOf(subtitleId) != address(0), "ER1");
            (uint8 state, , uint256 changeTime, , ) = IMurmes(Murmes)
                .getSubtitleBaseInfo(subtitleId);
            uint256 lockUpTime = IMurmes(Murmes).lockUpTime();
            require(block.timestamp <= changeTime + lockUpTime, "ER6");
            if (reason != Reason.MISTAKEN) {
                require(state == 1, "ER1-2");
            } else {
                require(state == 2, "ER1-3");
            }
        }
        if (subtitleReports[subtitleId].length > 0) {
            for (uint256 i; i < subtitleReports[subtitleId].length; i++) {
                uint256 reportId = subtitleReports[subtitleId][i];
                assert(reports[reportId].reason != reason);
            }
        }

        numberOfReports++;
        subtitleReports[subtitleId].push(numberOfReports);
        reports[numberOfReports].reason = reason;
        reports[numberOfReports].reporter = msg.sender;
        reports[numberOfReports].subtitleId = subtitleId;
        reports[numberOfReports].stringProof = stringProof;
        reports[numberOfReports].uintProof = uintProof;
        emit NewReport(reason, subtitleId, uintProof, stringProof, msg.sender);
    }

    /**
     * @notice 由多签返回经由 DAO 审核后的结果
     * @param reportId 举报 ID
     * @param resultProof 由链下 DAO 成员共识产生的摘要聚合而成的证明材料
     * @param result 审核结果，true 表示举报合理，通过
     * @param params 为了节省链上结算成本和优化逻辑，一些必要的参数由链下提供，这里指的是已经支付的字幕制作费用
     */
    function uploadDAOVerificationResult(
        uint256 reportId,
        string memory resultProof,
        bool result,
        uint256[] memory params
    ) public {
        require(
            IMurmes(Murmes).multiSig() == msg.sender ||
                IMurmes(Murmes).owner() == msg.sender,
            "ER5"
        );
        reports[reportId].resultProof = resultProof;
        reports[reportId].result = result;
        address access = IMurmes(Murmes).accessStrategy();
        if (result == true) {
            (
                ,
                uint256 taskId,
                ,
                address[] memory supporters,
                address[] memory dissenters
            ) = IMurmes(Murmes).getSubtitleBaseInfo(
                    reports[reportId].subtitleId
                );
            address st = IMurmes(Murmes).subtitleToken();
            (address maker, , , ) = IST(st).getSTBaseInfo(
                reports[reportId].subtitleId
            );
            if (reports[reportId].reason != Reason.MISTAKEN) {
                _deleteSubtitle(reports[reportId].subtitleId);
                _liquidatingMaliciousUser(access, supporters);
                _liquidatingNormalUser(access, dissenters);
                _liquidatingSubtitleMaker(maker, reportId);
                address platform = IMurmes(Murmes).getPlatformByTaskId(taskId);
                _processRevenue(
                    platform,
                    taskId,
                    params[0],
                    params[1],
                    params[2],
                    supporters,
                    maker,
                    params[3]
                );
            } else {
                _recoverSubtitle(reports[reportId].subtitleId);
                _liquidatingMaliciousUser(access, dissenters);
                _liquidatingNormalUser(access, supporters);
                _recoverSubtitleMaker(maker, access);
            }
        } else {
            _punishRepoter(reportId, access);
        }
        emit ReportResult(reportId, resultProof, result);
    }

    /**
     * @notice 当举报经由 DAO 审核不通过时，相应的 reporter 受到惩罚，这是为了防止恶意攻击的举措
     * @param reportId 举报 ID
     * @param access Murmes 合约的 access 策略合约地址
     */
    function _punishRepoter(uint256 reportId, address access) internal {
        (uint256 reputation, ) = IMurmes(Murmes).getUserBaseInfo(msg.sender);

        (
            uint256 reputationPunishment,
            uint256 tokenPunishment
        ) = IAccessStrategy(access).spread(reputation, 2);
        if (tokenPunishment == 0) tokenPunishment = 8 * 10**18;
        IMurmes(Murmes).updateUser(
            reports[reportId].reporter,
            int256(reputationPunishment) * -1,
            int256(tokenPunishment) * -1
        );
    }

    /**
     * @notice 删除恶意字幕，并撤销后续版本的有效性
     * @param subtitleId 被举报字幕 ST ID
     */
    function _deleteSubtitle(uint256 subtitleId) internal {
        IMurmes(Murmes).holdSubtitleStateByDAO(subtitleId, 2);
        address svm = IMurmes(Murmes).versionManagement();
        ISubtitleVersionManagement(svm).reportInvalidVersion(subtitleId, 0);
    }

    /**
     * @notice 当字幕是被恶意举报导致删除时，用于恢复字幕的有效性，由于无法确定对后续版本的影响，并未对版本状态作更新，所以字幕制作者可能蒙受损失
     * @param subtitleId 被举报的 ST ID
     */
    function _recoverSubtitle(uint256 subtitleId) internal {
        IMurmes(Murmes).holdSubtitleStateByDAO(subtitleId, 0);
    }

    /**
     * @notice 清算恶意评价者
     * @param access Murmes 合约的 access 策略合约地址
     * @param suppoters 恶意评价者
     */
    function _liquidatingMaliciousUser(
        address access,
        address[] memory suppoters
    ) internal {
        for (uint256 i; i < suppoters.length; i++) {
            (uint256 reputation, ) = IMurmes(Murmes).getUserBaseInfo(
                suppoters[i]
            );
            uint256 lastReputation = IAccessStrategy(access).lastReputation(
                reputation,
                1
            );
            (, uint256 tokenPunishment1) = IAccessStrategy(access).spread(
                lastReputation,
                1
            );
            // 一般来说，lastReputation 小于 reputation
            (
                uint256 reputationPunishment,
                uint256 tokenPunishment2
            ) = IAccessStrategy(access).spread(lastReputation, 2);
            int256 spread = int256(lastReputation) -
                int256(reputation) -
                int256(reputationPunishment);
            // 当 Zimu 激励代币发送完毕时，恶意用户获得额外的惩罚 tokenFixedReward
            uint256 punishmentToken = tokenPunishment1 + tokenPunishment2 >
                4 * 10**18
                ? tokenPunishment1 + tokenPunishment2
                : 4 * 10**18;
            IMurmes(Murmes).updateUser(
                suppoters[i],
                spread,
                int256(punishmentToken) * -1
            );
        }
    }

    /**
     * @notice 恢复诚实评价者被系统扣除的信誉度和代币
     * @param access Murmes 合约的 access 策略合约地址
     * @param dissenters 诚实评价者
     */
    function _liquidatingNormalUser(address access, address[] memory dissenters)
        internal
    {
        for (uint256 i; i < dissenters.length; i++) {
            (uint256 reputation, ) = IMurmes(Murmes).getUserBaseInfo(
                dissenters[i]
            );
            uint256 lastReputation = IAccessStrategy(access).lastReputation(
                reputation,
                2
            );
            (, uint256 tokenReward) = IAccessStrategy(access).spread(
                lastReputation,
                2
            );
            // 一般来说，lastReputation 大于 reputation
            tokenReward = tokenReward > 1 * 10**18 ? tokenReward : 1 * 10**18;
            int256 spread = int256(lastReputation) - int256(reputation) + 10;
            address vault = IMurmes(Murmes).vault();
            address zimu = IMurmes(Murmes).zimuToken();
            // 当 Zimu 激励代币发送完毕时，诚实用户获得额外的奖励 tokenFixedReward
            IVault(vault).transferPenalty(zimu, dissenters[i], tokenReward);
            IMurmes(Murmes).updateUser(dissenters[i], spread, 0);
        }
    }

    /**
     * @notice 清算恶意字幕制作者
     * @param maker 恶意字幕制作者
     * @param reportId 举报 ID
     */
    function _liquidatingSubtitleMaker(address maker, uint256 reportId)
        internal
    {
        (uint256 reputation, int256 deposit) = IMurmes(Murmes).getUserBaseInfo(
            maker
        );
        if (deposit < 0) deposit = 0;
        // 恶意字幕能够被确认，说明字幕制作者贿赂了支持者，负主要责任，进行最严厉的惩罚
        IMurmes(Murmes).updateUser(
            maker,
            int256(reputation) * -1 + 10,
            int256(deposit) * -1
        );
        if (deposit > 0) {
            _rewardRepoter(uint256(deposit), reportId);
        }
    }

    /**
     * @notice 奖励举报人，当举报验证通过时
     * @param deposit 恶意字幕制作者被扣除的 Zimu 代币数
     * @param reportId 举报 ID
     */
    function _rewardRepoter(uint256 deposit, uint256 reportId) internal {
        address vault = IMurmes(Murmes).vault();
        address zimu = IMurmes(Murmes).zimuToken();
        IVault(vault).transferPenalty(
            zimu,
            reports[reportId].reporter,
            (deposit * 90) / 100
        );
    }

    /**
     * @notice 当字幕被恶意举报导致删除时，恢复字幕制作者被扣除的信誉度和代币
     * @param maker 字幕制作者
     * @param access Murmes 合约的 access 策略合约地址
     */
    function _recoverSubtitleMaker(address maker, address access) internal {
        (uint256 reputation, ) = IMurmes(Murmes).getUserBaseInfo(maker);
        uint256 lastReputation = IAccessStrategy(access).lastReputation(
            reputation,
            2
        );
        uint8 multipler = IAccessStrategy(access).multiplier();
        uint256 _reputationSpread = ((lastReputation - reputation) *
            multipler) / 100;
        lastReputation = reputation + _reputationSpread;

        (, uint256 tokenPunishment) = IAccessStrategy(access).spread(
            lastReputation,
            1
        );
        // 多补偿被扣掉代币数的百分之三
        address vault = IMurmes(Murmes).vault();
        address zimu = IMurmes(Murmes).zimuToken();
        // 当 Zimu 激励代币发送完毕时，诚实用户获得额外的奖励 tokenFixedReward
        tokenPunishment = (tokenPunishment * (multipler + 3)) / 100;
        IVault(vault).transferPenalty(
            zimu,
            maker,
            tokenPunishment > 3 * 10**18 ? tokenPunishment : 3 * 10**18
        );
        IMurmes(Murmes).updateUser(maker, int256(_reputationSpread), 0);
    }

    /**
     * @notice 清算收益
     * @param platform 字幕所属申请，申请所属视频，视频所属的平台（申请所属的平台）
     * @param taskId 申请/任务 ID
     * @param share 在结算时每个字幕支持者获得的代币数量
     * @param main 字幕制作者获得的代币数量
     * @param all 申请中设定的字幕制作总费用
     * @param suppoters 字幕的支持者，分成收益的评价者
     * @param maker 字幕制作者
     * @param day 结算发生的日期
     */
    function _processRevenue(
        address platform,
        uint256 taskId,
        uint256 share,
        uint256 main,
        uint256 all,
        address[] memory suppoters,
        address maker,
        uint256 day
    ) internal {
        require(share * suppoters.length + main == all, "ER1");
        for (uint256 i; i < suppoters.length; i++) {
            IMurmes(Murmes).updateLockReward(
                platform,
                day,
                int256(share) * -1,
                suppoters[i]
            );
        }
        IMurmes(Murmes).updateLockReward(
            platform,
            day,
            int256(main) * -1,
            maker
        );
        // 重置申请
        IMurmes(Murmes).resetApplication(taskId, all);
    }
}
