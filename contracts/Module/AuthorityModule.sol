// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/IAuthorityModule.sol";
import "../common/token/ERC20/IERC20.sol";

contract AuthorityStrategy is IAuthorityModule {
    address public Murmes;

    uint16 constant MAX_TOTAL_DIVIDED = 7000;

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
    ) external returns (uint256) {
        require(msg.sender == Murmes, "AYM15");
        if (settlement == DataTypes.SettlementType.DIVIDEND) {
            require(
                uint16(amount) + occupied[boxId] <= MAX_TOTAL_DIVIDED,
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
     * @param platform 判断平台的有效性
     * @param caller 调用者
     * label AYS2
     */
    function isOwnCreateBoxAuthority(
        address platform,
        address caller
    ) external view {
        if (caller != address(this)) {
            require(flag > 0, "AYS2-5");
        }
    }

    /**
     * @notice 判断调用者是否有更新视频播放量/收益的权限
     * @param realId 视频（在第三方平台内）的真实 ID
     * @param counts 播放量
     * @param platform 第三方平台地址
     * @param caller 调用者
     * @return 可更新的播放量/收益
     * label AYS3
     */
    function isOwnUpdateViewCountsAuthority(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller
    ) external returns (uint256) {
        if (platform == Lens) {
            uint256 profileId = videoLensMap[realId].profileId;
            uint256 pubId = videoLensMap[realId].pubId;
            address module = ILensHub(Lens).getCollectModule(profileId, pubId);
            require(whitelistedLensModule[module] = true, "AYS3-5");
            uint256 amount = ILensFeeModuleForMurmes(module)
                .getTotalIncomeForMurmes(profileId, pubId);
            uint256 increase = amount > videoLensMap[realId].income
                ? amount - videoLensMap[realId].income
                : 0;
            videoLensMap[realId].income = amount;
            return increase;
        } else {
            require(platform == caller, "AYS3-5-2");
            return counts;
        }
    }

    /**
     * @notice 使用相应的VT兑换Lens作品的创作者的收益
     * @param amount 欲兑换数量，保持1:1
     * label AYS4
     */
    function swapInLens(uint256 amount) external returns (bool) {
        address platforms = IMurmes(Murmes).platforms();
        uint256 tokenId = IPlatform(platforms).getPlatformIdByAddress(Lens);
        address token = IPlatform(platforms).tokenGlobal();
        address vt = IMurmes(Murmes).videoToken();
        uint256 fix = amount / (10 ** 6);
        if (fix > 0) {
            IVT(vt).burn(msg.sender, tokenId, amount);
            require(IERC20(token).transfer(msg.sender, fix), "AYS4-12");
        }
        return true;
    }

    /**
     * @notice 获得可结算的代币数量
     * @param videoId 在Murmes协议内的视频顺位ID
     * @return 可结算的代币数量
     */
    function getSettlableInLens(uint256 videoId) public view returns (uint256) {
        address paltforms = IMurmes(Murmes).platforms();
        (address platform, uint256 realId, , , , , ) = IPlatform(paltforms)
            .getVideoBaseInfo(videoId);
        require(platform == Lens, "AYS6-1");
        uint256 profileId = videoLensMap[realId].profileId;
        uint256 pubId = videoLensMap[realId].pubId;
        address module = ILensHub(Lens).getCollectModule(profileId, pubId);
        uint256 amount = ILensFeeModuleForMurmes(module)
            .getTotalIncomeForMurmes(profileId, pubId);
        uint256 increase = amount > videoLensMap[realId].income
            ? amount - videoLensMap[realId].income
            : 0;
        return increase;
    }
}
