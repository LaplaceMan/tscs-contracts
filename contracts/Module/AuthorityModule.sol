// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IAuthorityModule.sol";

interface MurmesInterface {
    function isOperator(address operator) external view returns (bool);
}

contract AuthorityModule is IAuthorityModule {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 当采用分成结算策略时，单个Box已经分成过的比例
     */
    mapping(uint256 => uint16) occupied;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 判断调用者的申请权限
     * @param components Murmes全局组件合约
     * @param platform 所属平台地址
     * @param boxId box在第三方平台内的ID
     * @param source box源地址
     * @param caller 调用者
     * @param settlement 结算策略
     * @param amount 支付数量/比例
     * @return 在协议内该box的ID
     * Fn 1
     */
    function formatBoxIdOfPostTask(
        address components,
        address platform,
        uint256 boxId,
        string memory source,
        address caller,
        DataTypes.SettlementType settlement,
        uint256 amount
    ) external override returns (uint256) {
        require(msg.sender == Murmes, "AYM15");
        if (settlement == DataTypes.SettlementType.DIVIDEND) {
            require(
                uint16(amount) + occupied[boxId] <= Constant.MAX_TOTAL_DIVIDED,
                "AYM11"
            );
            occupied[boxId] += uint16(amount);
        }
        address platforms = IComponentGlobal(components).platforms();
        address authorityModule = IPlatforms(platforms)
            .getPlatformAuthorityModule(platform);

        uint256 id = IAuthorityBase(authorityModule).forPostTask(
            platform,
            boxId,
            source,
            caller,
            settlement
        );

        return id;
    }

    /**
     * @notice 判断调用者是否有创建Box的权限
     * @param platform Box所属平台
     * @param platformId Box所属平台的ID
     * @param authorityModule Box所属平台设置的特殊权限合约
     * @param caller 调用者
     * Fn 2
     */
    function isOwnCreateBoxAuthority(
        address platform,
        uint256 platformId,
        address authorityModule,
        address caller
    ) external view override returns (bool) {
        return
            IAuthorityBase(authorityModule).forCreateBox(
                platform,
                platformId,
                caller
            );
    }

    /**
     * @notice 判断调用者是否有更新Box收益的权限
     * @param realId Box在第三方平台内的真实ID
     * @param counts 收益数目
     * @param platform 第三方平台地址
     * @param caller 调用者
     * @param authorityModule Box所属平台设置的特殊权限合约
     * @return 实际可更新的收益
     * Fn 3
     */
    function formatCountsOfUpdateBoxRevenue(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller,
        address authorityModule
    ) external override returns (uint256) {
        require(MurmesInterface(Murmes).isOperator(msg.sender), "AYM35");
        return
            IAuthorityBase(authorityModule).forUpdateBoxRevenue(
                realId,
                counts,
                platform,
                caller
            );
    }

    /**
     * @notice 更新Box已使用的分成比例
     * @param boxId Box的唯一ID
     * @param amount 新增使用
     */
    function updateTaskAmountOccupied(uint256 boxId, uint256 amount) external {
        require(msg.sender == Murmes, "AYW45");
        occupied[boxId] += uint16(amount);
        require(
            uint16(amount) + occupied[boxId] <= Constant.MAX_TOTAL_DIVIDED,
            "AYM41"
        );
    }
}
