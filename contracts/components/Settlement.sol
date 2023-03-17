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

contract Settlement is ISettlement {
    address public Murmes;

    uint16 constant BASE_RATE = 10000;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 更新Item收益
     * @param taskId Item所属任务ID
     * @param counts 更新的收益
     * Fn 7
     */
    function updateItemRevenue(uint256 taskId, uint256 counts) external {
        address platform = IMurmes(Murmes).getPlatformAddressByTaskId(taskId);
        require(
            IMurmes(Murmes).isOperator(msg.sender) || msg.sender == platform,
            "75"
        );
        (DataTypes.SettlementType settlementType, , uint256 amount) = IMurmes(
            Murmes
        ).getTaskSettlementData(taskId);
        require(settlementType == DataTypes.SettlementType.DIVIDEND, "76");
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
    }

    /**
     * @notice 预结算收益，众包任务的结算类型为：一次性
     * @param taskId 众包任务ID
     */
    function preExtractForNormal(uint256 taskId) external {
        (DataTypes.SettlementType settlementType, ) = IMurmes(Murmes)
            .getTaskSettlementModuleAndItems(taskId);
        require(settlementType == DataTypes.SettlementType.ONETIME, "");
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address moduleGlobal = IMurmes(Murmes).moduleGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        address itemNFT = IComponentGlobal(componentGlobal).itemToken();
        (, uint16 rateAuditorDivide) = IPlatforms(platforms).getPlatformRate(
            address(this)
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
    }

    /**
     * @notice 预结算Box收益，同时完成众包任务结算
     * @param boxId Box ID
     * Fn 5
     */
    function preExtractOther(uint256 boxId) external {
        address componentGlobal = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(componentGlobal).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.unsettled > 0, "511");
        DataTypes.PlatformStruct memory platform = IPlatforms(platforms)
            .getPlatform(box.platform);
        uint256 unsettled = (platform.rateCountsToProfit *
            box.unsettled *
            (10**6)) / BASE_RATE;
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
    }

    /**
     * @notice 遍历结算Box的所有众包任务
     * @param unsettled 可支付代币数目
     * @param platform box所属平台
     * @param rateAuditorDivide 审核分成比率
     * Fn 12
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
