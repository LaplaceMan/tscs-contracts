// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IItemNFT.sol";
import "../interfaces/IPlatforms.sol";
import "../interfaces/ISettlement.sol";
import "../interfaces/IModuleGlobal.sol";
import "../interfaces/IPlatformToken.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/ISettlementModule.sol";
import {Constant} from "../libraries/Constant.sol";
import {Events} from "../libraries/Events.sol";

contract Settlement is ISettlement {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 更新Item收益
     * @param taskId Item所属任务ID
     * @param counts 更新的收益
     * Fn 1
     */
    function updateItemRevenue(uint256 taskId, uint256 counts) external {
        address platform = IMurmes(Murmes).getPlatformAddressByTaskId(taskId);
        require(
            IMurmes(Murmes).isOperator(msg.sender) || msg.sender == platform,
            "S15"
        );
        (DataTypes.SettlementType settlementType, , uint256 amount) = IMurmes(
            Murmes
        ).getTaskSettlementData(taskId);
        require(settlementType == DataTypes.SettlementType.DIVIDEND, "S16");
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        (uint16 rateCountsToProfit, ) = IPlatforms(platforms).getPlatformRate(
            platform
        );
        address moduleGlobal = IMurmes(Murmes).moduleGlobal();
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(settlementType);
        ISettlementModule(settlement).updateDebtOrRevenue(
            taskId,
            counts,
            amount,
            rateCountsToProfit
        );
        emit Events.ItemRevenueUpdate(taskId, counts);
    }

    /**
     * @notice 预结算收益，众包任务的结算类型为：一次性
     * @param taskId 众包任务ID
     * Fn 2
     */
    function preExtractForNormal(uint256 taskId) external {
        (DataTypes.SettlementType settlementType, ) = IMurmes(Murmes)
            .getTaskSettlementModuleAndItems(taskId);
        require(settlementType == DataTypes.SettlementType.ONETIME, "S26");
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address moduleGlobal = IMurmes(Murmes).moduleGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        address itemNFT = IComponentGlobal(componentGlobal).itemToken();
        (, uint16 rateAuditorDivide) = IPlatforms(platforms).getPlatformRate(
            Murmes
        );
        address settlement = IModuleGlobal(moduleGlobal)
            .getSettlementModuleAddress(DataTypes.SettlementType.ONETIME);
        (
            uint256 adoptedItemId,
            address currency,
            address[] memory supporters
        ) = IMurmes(Murmes).getAdoptedItemData(taskId);
        ISettlementModule(settlement).settlement(
            taskId,
            currency,
            IItemNFT(itemNFT).ownerOf(adoptedItemId),
            0,
            rateAuditorDivide,
            supporters
        );
        emit Events.ExtractRevenuePre(taskId, msg.sender);
    }

    /**
     * @notice 预结算Box收益，同时完成众包任务结算
     * @param boxId Box ID
     * Fn 3
     */
    function preExtractForOther(uint256 boxId) external {
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.unsettled > 0, "S31");
        DataTypes.PlatformStruct memory platform = IPlatforms(platforms)
            .getPlatform(box.platform);
        uint256 unsettled = (platform.rateCountsToProfit *
            box.unsettled *
            (10 ** 6)) / Constant.BASE_RATE;
        uint256 surplus = _ergodic(
            IComponentGlobal(componentGlobal).itemToken(),
            unsettled,
            box.platform,
            box.tasks,
            platform.rateAuditorDivide
        );

        if (surplus > 0) {
            address platformToken = IComponentGlobal(componentGlobal)
                .platformToken();
            IPlatformToken(platformToken).mintPlatformTokenByMurmes(
                platform.platformId,
                box.creator,
                surplus
            );
        }
        IPlatforms(platforms).updateBoxUnsettledRevenueByMurmes(
            boxId,
            int256(box.unsettled) * -1
        );
        emit Events.ExtractRevenue(boxId, msg.sender);
    }

    // ***************** Internal Functions *****************
    /**
     * @notice 遍历结算Box的所有众包任务
     * @param itemToken Item NFT组件合约
     * @param unsettled 可支付代币数目
     * @param platform box所属平台
     * @param tasks box的所有众包任务ID集合
     * @param rateAuditorDivide 审核分成比率
     * Fn 4
     */
    function _ergodic(
        address itemToken,
        uint256 unsettled,
        address platform,
        uint256[] memory tasks,
        uint16 rateAuditorDivide
    ) internal returns (uint256) {
        for (uint256 i = 0; i < tasks.length; i++) {
            (uint256 adoptedItemId, , address[] memory supporters) = IMurmes(
                Murmes
            ).getAdoptedItemData(tasks[i]);
            if (adoptedItemId > 0 && unsettled > 0) {
                (DataTypes.SettlementType settlementType, ) = IMurmes(Murmes)
                    .getTaskSettlementModuleAndItems(tasks[i]);
                address settlement = IModuleGlobal(
                    IMurmes(Murmes).moduleGlobal()
                ).getSettlementModuleAddress(settlementType);
                uint256 itemGetRevenue = ISettlementModule(settlement)
                    .settlement(
                        tasks[i],
                        platform,
                        IItemNFT(itemToken).ownerOf(adoptedItemId),
                        unsettled,
                        rateAuditorDivide,
                        supporters
                    );
                unsettled -= itemGetRevenue;
            }
        }
        return unsettled;
    }
}
