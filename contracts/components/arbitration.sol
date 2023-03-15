// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IVault.sol";
import "../interfaces/IMurmes.sol";
import "../interfaces/IItemNFT.sol";
import "../interfaces/IAccessModule.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IItemVersionManagement.sol";

contract Arbitration {
    address public Murmes;

    uint256 numberOfReports;

    uint256 constant MIN_PUNISHMENT_FOR_REPOTER = 8 * 10 ** 18;

    uint256 constant MIN_PUNISHMENT_FOR_VALIDATOR = 4 * 10 ** 18;

    uint256 constant MIN_COMPENSATE_FOR_USER = 1 * 10 ** 18;

    uint256 constant MIN_COMPENSATE_REPUTATION = 15;

    mapping(uint256 => reportItem) reports;

    mapping(uint256 => uint256[]) itemReports;

    /**
     * @notice 举报理由
     * @param PLAGIARIZE 侵权
     * @param WRONG 恶意
     * @param MISTAKEN 误删
     * @param MISMATCH 指纹不对应
     */
    enum Reason {
        PLAGIARIZE,
        WRONG,
        MISTAKEN,
        MISMATCH
    }

    struct reportItem {
        address reporter;
        Reason reason;
        uint256 itemId;
        uint256 uintProof;
        string stringProof;
        string resultProof;
        bool result;
    }

    event NewReport(
        Reason reason,
        uint256 itemId,
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
     * @param itemId 被举报Item的ID
     * @param uintProof 证明材料，类型为 UINT
     * @param stringProof 证明材料，类型为 STRING
     * Fn 1
     */
    function report(
        Reason reason,
        uint256 itemId,
        uint256 uintProof,
        string memory stringProof
    ) public {
        {
            (uint256 reputation, int256 deposit) = IMurmes(Murmes)
                .getUserBaseData(msg.sender);
            address components = IMurmes(Murmes).componentGlobal();
            address access = IComponentGlobal(components).access();
            require(IAccessModule(access).access(reputation, deposit), "A15");
            require(
                deposit >= int256(IAccessModule(access).depositUnit()),
                "A15-2"
            );
            address itemNFT = IComponentGlobal(components).itemToken();
            require(IItemNFT(itemNFT).ownerOf(itemId) != address(0), "A11");
            DataTypes.ItemStruct memory item = IMurmes(Murmes).itemsNFT(itemId);
            uint256 lockUpTime = IComponentGlobal(components).lockUpTime();
            require(
                block.timestamp <= item.stateChangeTime + lockUpTime,
                "A16"
            );
            if (reason != Reason.MISTAKEN) {
                require(item.state == DataTypes.ItemState.ADOPTED, "A11-2");
            } else {
                require(item.state == DataTypes.ItemState.DELETED, "A11-3");
            }
        }

        if (itemReports[itemId].length > 0) {
            for (uint256 i = 0; i < itemReports[itemId].length; i++) {
                uint256 reportId = itemReports[itemId][i];
                assert(reports[reportId].reason != reason);
            }
        }

        numberOfReports++;
        itemReports[itemId].push(numberOfReports);
        reports[numberOfReports].reason = reason;
        reports[numberOfReports].reporter = msg.sender;
        reports[numberOfReports].itemId = itemId;
        reports[numberOfReports].stringProof = stringProof;
        reports[numberOfReports].uintProof = uintProof;
        emit NewReport(reason, itemId, uintProof, stringProof, msg.sender);
    }

    /**
     * @notice 由多签返回经由DAO审核后的结果
     * @param reportId 唯一标识举报的ID
     * @param resultProof 由链下DAO成员共识产生的摘要聚合而成的证明材料
     * @param result 审核结果，true表示举报合理，通过
     * @param params 为了节省链上结算成本和优化逻辑，一些必要的参数由链下提供，这里指的是已经支付的字幕制作费用
     * Fn 2
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
            "A25"
        );
        reports[reportId].resultProof = resultProof;
        reports[reportId].result = result;
        address components = IMurmes(Murmes).componentGlobal();
        address access = IComponentGlobal(components).access();
        if (result == true) {
            DataTypes.ItemStruct memory item = IMurmes(Murmes).itemsNFT(
                reports[reportId].itemId
            );
            address itemNFT = IComponentGlobal(components).itemToken();
            (address maker, , ) = IItemNFT(itemNFT).getItemBaseData(
                reports[reportId].itemId
            );
            if (reports[reportId].reason != Reason.MISTAKEN) {
                _deleteItem(components, reports[reportId].itemId);
                _liquidatingMaliciousUser(access, item.supporters);
                _liquidatingNormalUser(access, components, item.opponents);
                _liquidatingItemMaker(maker, components, reportId);
                address platform = IMurmes(Murmes).getPlatformAddressByTaskId(
                    item.taskId
                );
                _processRevenue(
                    platform,
                    item.taskId,
                    params[0],
                    params[1],
                    params[2],
                    item.supporters,
                    maker,
                    params[3]
                );
            } else {
                _recoverItem(reports[reportId].itemId);
                _liquidatingMaliciousUser(access, item.opponents);
                _liquidatingNormalUser(access, components, item.supporters);
                _recoverItemMaker(maker, access, components);
            }
        } else {
            _punishRepoter(reportId, access);
        }
        emit ReportResult(reportId, resultProof, result);
    }

    /**
     * @notice 当举报经由DAO审核不通过时，相应的reporter受到惩罚，这是为了防止恶意攻击的举措
     * @param reportId 唯一标识举报的ID
     * @param access Murmes合约的access模块合约地址
     * Fn 3
     */
    function _punishRepoter(uint256 reportId, address access) internal {
        (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(msg.sender);

        (uint256 reputationPunishment, uint256 tokenPunishment) = IAccessModule(
            access
        ).variation(reputation, 2);
        if (tokenPunishment == 0) tokenPunishment = MIN_PUNISHMENT_FOR_REPOTER;
        IMurmes(Murmes).updateUser(
            reports[reportId].reporter,
            int256(reputationPunishment) * -1,
            int256(tokenPunishment) * -1
        );
    }

    /**
     * @notice 删除恶意Item，并撤销后续版本的有效性
     * @param itemId 被举报的Item的ID
     * Fn 4
     */
    function _deleteItem(address components, uint256 itemId) internal {
        IMurmes(Murmes).holdItemStateByDAO(itemId, DataTypes.ItemState.DELETED);
        address vm = IComponentGlobal(components).version();
        IItemVersionManagement(vm).reportInvalidVersion(itemId, 0);
    }

    /**
     * @notice 当Item是被恶意举报导致删除时，用于恢复Item的有效性，由于无法确定对后续版本的影响，并未对版本状态作更新，所以Item制作者可能蒙受损失
     * @param itemId 被举报的Item的ID
     * Fn 5
     */
    function _recoverItem(uint256 itemId) internal {
        IMurmes(Murmes).holdItemStateByDAO(itemId, DataTypes.ItemState.NORMAL);
    }

    /**
     * @notice 清算恶意评价者
     * @param access Murmes合约的access模块合约地址
     * @param users 恶意评价者
     * Fn 6
     */
    function _liquidatingMaliciousUser(
        address access,
        address[] memory users
    ) internal {
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(users[i]);
            uint256 lastReputation = IAccessModule(access).lastReputation(
                reputation,
                1
            );
            // 一般来说，lastReputation 小于 reputation
            (
                uint256 reputationPunishment,
                uint256 tokenPunishment
            ) = IAccessModule(access).variation(lastReputation, 2);
            int256 variation = int256(lastReputation) -
                int256(reputation) -
                int256(reputationPunishment);
            uint256 punishmentToken = tokenPunishment >
                MIN_PUNISHMENT_FOR_VALIDATOR
                ? tokenPunishment
                : MIN_PUNISHMENT_FOR_VALIDATOR;
            IMurmes(Murmes).updateUser(
                users[i],
                variation,
                int256(punishmentToken) * -1
            );
        }
    }

    /**
     * @notice 恢复诚实评价者被系统扣除的信誉度和代币
     * @param access Murmes合约的access模块合约地址
     * @param components 全局组件模块合约地址
     * @param users 诚实评价者
     * Fn 7
     */
    function _liquidatingNormalUser(
        address access,
        address components,
        address[] memory users
    ) internal {
        for (uint256 i = 0; i < users.length; i++) {
            (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(users[i]);
            uint256 lastReputation = IAccessModule(access).lastReputation(
                reputation,
                2
            );
            (, uint256 tokenReward) = IAccessModule(access).variation(
                lastReputation,
                2
            );
            // 一般来说，lastReputation 大于 reputation
            tokenReward = tokenReward > MIN_COMPENSATE_FOR_USER
                ? tokenReward
                : MIN_COMPENSATE_FOR_USER;
            int256 variation = int256(lastReputation) -
                int256(reputation) +
                int256(MIN_COMPENSATE_REPUTATION);
            address vault = IComponentGlobal(components).vault();
            address token = IComponentGlobal(components)
                .defaultDespoitableToken();
            IVault(vault).transferPenalty(token, users[i], tokenReward);
            IMurmes(Murmes).updateUser(users[i], variation, 0);
        }
    }

    /**
     * @notice 清算恶意Item制作者
     * @param maker 恶意Item制作者
     * @param components 全局组件模块合约
     * @param reportId 唯一标识举报的ID
     * Fn 8
     */
    function _liquidatingItemMaker(
        address maker,
        address components,
        uint256 reportId
    ) internal {
        (uint256 reputation, int256 deposit) = IMurmes(Murmes).getUserBaseData(
            maker
        );
        int256 oldDeposit = deposit;
        if (deposit < 0) oldDeposit = 0;

        IMurmes(Murmes).updateUser(
            maker,
            int256(reputation) * -1,
            int256(oldDeposit) * -1
        );
        if (deposit > 0) {
            _rewardRepoter(components, uint256(deposit), reportId);
        }
    }

    /**
     * @notice 奖励举报人，当举报验证通过时
     * @param components 全局组件合约
     * @param deposit 恶意Item制作者被扣除的代币数
     * @param reportId 唯一标识举报的ID
     * Fn 9
     */
    function _rewardRepoter(
        address components,
        uint256 deposit,
        uint256 reportId
    ) internal {
        address vault = IComponentGlobal(components).vault();
        address token = IComponentGlobal(components).defaultDespoitableToken();
        IVault(vault).transferPenalty(
            token,
            reports[reportId].reporter,
            deposit / 2
        );
    }

    /**
     * @notice 当Item被恶意举报导致删除时，恢复Item制作者被扣除的信誉度和代币
     * @param maker Item制作者
     * @param access Murmes的access模块合约地址
     * @param components 全局组件模块合约
     * Fn 10
     */
    function _recoverItemMaker(
        address maker,
        address access,
        address components
    ) internal {
        (uint256 reputation, ) = IMurmes(Murmes).getUserBaseData(maker);
        uint256 lastReputation = IAccessModule(access).lastReputation(
            reputation,
            2
        );
        uint8 multipler = IAccessModule(access).multiplier();
        uint256 _reputationSpread = ((lastReputation - reputation) *
            multipler) / 100;
        lastReputation = reputation + _reputationSpread;

        (, uint256 tokenPunishment) = IAccessModule(access).variation(
            lastReputation,
            1
        );
        if (tokenPunishment > 0) {
            // 多补偿被扣掉代币数的百分之一
            address vault = IComponentGlobal(components).vault();
            address token = IComponentGlobal(components)
                .defaultDespoitableToken();
            tokenPunishment = (tokenPunishment * (multipler + 1)) / 100;
            IVault(vault).transferPenalty(token, maker, tokenPunishment);
        }

        IMurmes(Murmes).updateUser(maker, int256(_reputationSpread), 0);
    }

    /**
     * @notice 清算收益
     * @param platform Item所属众包任务，申请所属Box，Box所属的平台
     * @param taskId 申请/任务 ID
     * @param share 在结算时每个Item支持者获得的代币数量
     * @param main Item制作者获得的代币数量
     * @param all 申请中设定的Item制作总费用
     * @param suppoters Item的支持者，分成收益的评价者
     * @param maker Item制作者
     * @param day 结算发生的日期
     * Fn 11
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
        require(share * suppoters.length + main == all, "A111");
        for (uint256 i = 0; i < suppoters.length; i++) {
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
        IMurmes(Murmes).resetTask(taskId, all);
    }
}
