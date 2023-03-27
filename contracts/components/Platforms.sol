// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IPlatforms.sol";
import "../interfaces/ISettlement.sol";
import "../interfaces/IModuleGlobal.sol";
import "../interfaces/IPlatformToken.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IAuthorityModule.sol";
import {Events} from "../libraries/Events.sol";

contract Platforms is IPlatforms {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 注册的Box总数
     */
    uint256 public totalBoxes;
    /**
     * @notice 注册的第三方平台总数
     */
    uint256 public totalPlatforms;
    /**
     * @notice 记录Box的详细信息
     */
    mapping(uint256 => DataTypes.BoxStruct) boxes;
    /**
     * @notice 记录第三方平台的详细信息
     */
    mapping(address => DataTypes.PlatformStruct) platforms;
    /**
     * @notice Box在第三方平台内ID与在Murmes内ID的映射
     */
    mapping(address => mapping(uint256 => uint256)) idRealToMurmes;

    constructor(address ms) {
        Murmes = ms;
        platforms[ms].name = "Murmes";
        platforms[ms].symbol = "Murmes";
        platforms[ms].rateAuditorDivide = 100;
    }

    // Fn 1
    modifier auth() {
        require(msg.sender == Murmes, "P15");
        _;
    }

    /**
     * @notice 第三方平台加入Murmes
     * @param platform 平台地址
     * @param name 平台名称
     * @param symbol 平台符号
     * @param rate1 收益转化率
     * @param rate2 审核分成率
     * @param authority 与该平台相关的特殊权限管理合约
     * @return 根据顺位的Platform ID
     * Fn 2
     */
    function addPlatform(
        address platform,
        string memory name,
        string memory symbol,
        uint16 rate1,
        uint16 rate2,
        address authority
    ) external returns (uint256) {
        require(rate1 > 0 && rate2 > 0, "P21");
        require(platforms[platform].platformId == 0, "P20");
        require(IMurmes(Murmes).owner() == msg.sender, "P25");
        address moduleGlobal = IMurmes(Murmes).moduleGlobal();
        require(
            IModuleGlobal(moduleGlobal).isAuthorityModuleWhitelisted(authority),
            "P26"
        );
        totalPlatforms++;
        platforms[platform] = (
            DataTypes.PlatformStruct({
                name: name,
                symbol: symbol,
                platformId: totalPlatforms,
                rateCountsToProfit: rate1,
                rateAuditorDivide: rate2,
                authorityModule: authority
            })
        );
        address components = IMurmes(Murmes).componentGlobal();
        address platformToken = IComponentGlobal(components).platformToken();
        IPlatformToken(platformToken).createPlatformToken(
            symbol,
            platform,
            totalPlatforms
        );
        emit Events.RegisterPlatform(
            platform,
            name,
            symbol,
            rate1,
            rate2,
            authority,
            totalPlatforms
        );
        return totalPlatforms;
    }

    /**
     * @notice 平台更新自己的比率信息
     * @param rate1 新的收益转换率
     * @param rate2 新的审核分成率
     * Fn 3
     */
    function setPlatformRate(uint16 rate1, uint16 rate2) external override {
        require(platforms[msg.sender].platformId != 0, "P32");
        if (rate1 != 0) {
            platforms[msg.sender].rateCountsToProfit = rate1;
        }
        if (rate2 != 0) {
            platforms[msg.sender].rateAuditorDivide = rate2;
        }
        emit Events.PlatformStateUpdate(msg.sender, rate1, rate2);
    }

    /**
     * @notice Murmes 设置自己的审核分成率
     * @param auditorDivide 新的审核分成率
     * Fn 4
     */
    function setMurmesAuditorDivideRate(uint16 auditorDivide) external {
        require(IMurmes(Murmes).owner() == msg.sender, "P45");
        platforms[Murmes].rateAuditorDivide = auditorDivide;
    }

    /**
     * @notice Murmes 设置自己的特殊权限管理模块
     * @param newModule 新模块的合约
     * Fn 5
     */
    function setMurmesAuthorityModule(address newModule) external {
        require(IMurmes(Murmes).owner() == msg.sender, "P55");
        platforms[Murmes].authorityModule = newModule;
    }

    /**
     * @notice 创建Box
     * @param realId Box的真实ID
     * @param platform Box所属平台
     * @param creator Box创造者
     * @return 根据顺位的Box ID
     * Fn 6
     */
    function createBox(
        uint256 realId,
        address platform,
        address creator
    ) external override returns (uint256) {
        address components = IMurmes(Murmes).componentGlobal();
        address authority = IComponentGlobal(components).authority();
        require(
            IAuthorityModule(authority).isOwnCreateBoxAuthority(
                platform,
                platforms[platform].platformId,
                platforms[platform].authorityModule,
                msg.sender
            ),
            "P65"
        );
        totalBoxes++;
        require(idRealToMurmes[platform][realId] == 0);
        boxes[totalBoxes].platform = platform;
        boxes[totalBoxes].id = realId;
        boxes[totalBoxes].creator = creator;
        idRealToMurmes[platform][realId] = totalBoxes;
        emit Events.BoxCreated(realId, platform, creator, totalBoxes);
        return totalBoxes;
    }

    /**
     * @notice 更新与Box有关的Task集合
     * @param boxId 唯一标识特定Box
     * @param tasks 根据结算策略ID排好的Task结合
     * Fn 7
     */
    function updateBoxTasksByMurmes(
        uint256 boxId,
        uint256[] memory tasks
    ) external override auth {
        boxes[boxId].tasks = tasks;
    }

    /**
     * @notice 更新Box未结算的数目
     * @param boxId 唯一标识特定Box的ID
     * @param differ 变化量
     * Fn 8
     */
    function updateBoxUnsettledRevenueByMurmes(
        uint256 boxId,
        int256 differ
    ) external override {
        require(IMurmes(Murmes).isOperator(msg.sender), "P85");
        int256 unsettled = int256(boxes[boxId].unsettled) + differ;
        boxes[boxId].unsettled = unsettled > 0 ? uint256(unsettled) : 0;
    }

    /**
     * @notice 更新多个Box未结算的收益
     * @param ids 唯一标识Box的ID集合
     * @param amounts 相应的未结算数目
     * Fn 9
     */
    function updateBoxesRevenue(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external override {
        assert(ids.length == amounts.length);
        address components = IMurmes(Murmes).componentGlobal();
        address authority = IComponentGlobal(components).authority();
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 amount = IAuthorityModule(authority)
                .formatCountsOfUpdateBoxRevenue(
                    boxes[ids[i]].id,
                    amounts[i],
                    boxes[ids[i]].platform,
                    msg.sender,
                    platforms[boxes[ids[i]].platform].authorityModule
                );
            boxes[ids[i]].unsettled += amount;
            for (uint256 j; j < boxes[ids[i]].tasks.length; j++) {
                uint256 taskId = boxes[ids[i]].tasks[j];
                (
                    DataTypes.SettlementType settlementType,
                    uint256[] memory items
                ) = IMurmes(Murmes).getTaskSettlementModuleAndItems(taskId);
                if (
                    settlementType == DataTypes.SettlementType.DIVIDEND &&
                    items.length > 0
                ) {
                    address settlement = IComponentGlobal(components)
                        .settlement();
                    ISettlement(settlement).updateItemRevenue(taskId, amount);
                }
            }
            emit Events.BoxRevenueUpdate(ids[i], amounts[i], msg.sender);
        }
    }

    // ***************** View Functions *****************
    function getBox(
        uint256 boxId
    ) external view override returns (DataTypes.BoxStruct memory) {
        return boxes[boxId];
    }

    function getBoxTasks(
        uint256 boxId
    ) external view override returns (uint256[] memory) {
        return boxes[boxId].tasks;
    }

    function getBoxOrderIdByRealId(
        address platfrom,
        uint256 realId
    ) external view override returns (uint256) {
        return idRealToMurmes[platfrom][realId];
    }

    function getPlatform(
        address platform
    ) external view override returns (DataTypes.PlatformStruct memory) {
        return platforms[platform];
    }

    function getPlatformRate(
        address platform
    ) external view override returns (uint16, uint16) {
        return (
            platforms[platform].rateCountsToProfit,
            platforms[platform].rateAuditorDivide
        );
    }

    function getPlatformIdByAddress(
        address platform
    ) external view override returns (uint256) {
        return platforms[platform].platformId;
    }

    function getPlatformAuthorityModule(
        address platform
    ) external view override returns (address) {
        return platforms[platform].authorityModule;
    }
}
