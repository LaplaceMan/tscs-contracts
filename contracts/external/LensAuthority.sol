// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
import "../interfaces/IPlatformToken.sol";
import "../common/token/ERC20/IERC20.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/ILensFeeModuleForMurmes.sol";
import {ILensHub} from "../interfaces/ILensHub.sol";

interface MurmesInterface {
    function componentGlobal() external view returns (address);

    function owner() external view returns (address);

    function isOperator(address operator) external view returns (bool);
}

contract LensAuthority is IAuthorityBase {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice Lens数据存储合约地址
     */
    address public Lens;
    /**
     * @notice 记录Box的Real ID与Lens publication的映射
     */
    mapping(uint256 => LensItem) boxLensItemMap;
    /**
     * @notice 记录白名单内的Lens collect模块合约地址
     */
    mapping(address => bool) whitelistedLensModule;

    event SetWhitelistedLensModule(address module, bool result);

    constructor(address ms, address lens) {
        Lens = lens;
        Murmes = ms;
    }

    struct LensItem {
        uint256 profileId; // profile的ID
        uint256 pubId; // publication的ID
        uint256 revenue; // 已获得的总代币收益
    }

    /**
     * @notice 提交任务之前，判断提交者的权限
     * @param platform 任务所属平台地址
     * @param boxId 任务所属Box的ID
     * @param source 众包任务的源地址（详细说明）
     * @param caller 提交众包任务者
     * @return 实际与该众包任务关联Box的ID
     * Fn 1
     */
    function forPostTask(
        address platform,
        uint256 boxId,
        string memory source,
        address caller,
        DataTypes.SettlementType
    ) external override returns (uint256) {
        require(MurmesInterface(Murmes).isOperator(msg.sender), "LA15");
        (uint256 profileId, bool result) = _stringToUint256(source);
        require(result, "LA11");
        address owner = ILensHub(Lens).ownerOf(profileId);
        require(owner == caller, "LA15-2");
        address module = ILensHub(Lens).getCollectModule(profileId, boxId);
        require(whitelistedLensModule[module] = true, "LA16");
        uint256 realId = uint256(keccak256(abi.encode(profileId, boxId)));
        address components = MurmesInterface(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        uint256 orderId = IPlatforms(platforms).getBoxOrderIdByRealId(
            platform,
            realId
        );
        if (orderId == 0) {
            orderId = IPlatforms(platforms).createBox(realId, Lens, caller);
            boxLensItemMap[realId].profileId = profileId;
            boxLensItemMap[realId].pubId = boxId;
        }
        return orderId;
    }

    /**
     * @notice 创建Box之前，判断创建者权限
     * @param platform Box所属的平台地址
     * @return 是否有权限
     * Fn 2
     */
    function forCreateBox(
        address platform,
        uint256,
        address
    ) external view override returns (bool) {
        if (
            platform != Lens || !MurmesInterface(Murmes).isOperator(msg.sender)
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice 更新Box收益之前，检查更新者权限
     * @param realId Box在第三方平台内的real ID
     * @return 最终可更新的收益数量
     * Fn 3
     */
    function forUpdateBoxRevenue(
        uint256 realId,
        uint256,
        address,
        address
    ) external override returns (uint256) {
        require(MurmesInterface(Murmes).isOperator(msg.sender), "LA35");
        uint256 profileId = boxLensItemMap[realId].profileId;
        uint256 pubId = boxLensItemMap[realId].pubId;
        address module = ILensHub(Lens).getCollectModule(profileId, pubId);
        require(whitelistedLensModule[module] = true, "LA36");
        uint256 amount = ILensFeeModuleForMurmes(module)
            .getTotalRevenueForMurmes(profileId, pubId);
        uint256 increase = amount > boxLensItemMap[realId].revenue
            ? amount - boxLensItemMap[realId].revenue
            : 0;
        boxLensItemMap[realId].revenue = amount;
        return increase;
    }

    /**
     * @notice 代币兑换（平台代币 => 默认支持的质押代币）
     * @param amount 兑换数量
     * @return 最终兑换回的数量
     * Fn 4
     */
    function swap(uint256 amount) external returns (uint256) {
        address components = MurmesInterface(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        uint256 tokenId = IPlatforms(platforms).getPlatformIdByAddress(Lens);
        address defaultToken = IComponentGlobal(components)
            .defaultDespoitableToken();
        address platformToken = IComponentGlobal(components).platformToken();
        uint256 fix = amount / (10 ** 6);
        if (fix > 0) {
            IPlatformToken(platformToken).burn(msg.sender, tokenId, amount);
            require(IERC20(defaultToken).transfer(msg.sender, fix), "LA412");
        }
        return fix;
    }

    /**
     * @notice 设置支持的Lens collect模块合约地址
     * @param module 模块合约地址
     * @param result 是否支持
     * Fn 5
     */
    function setWhitelistedLensModule(address module, bool result) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "LA65");
        whitelistedLensModule[module] = result;
        emit SetWhitelistedLensModule(module, result);
    }

    // ***************** Internal Functions *****************
    function _stringToUint256(
        string memory str
    ) internal pure returns (uint256 value, bool result) {
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (
                (uint8(bytes(str)[i]) - 48) < 0 ||
                (uint8(bytes(str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            value +=
                (uint8(bytes(str)[i]) - 48) *
                10 ** (bytes(str).length - i - 1);
        }
        return (value, true);
    }

    // ***************** View Functions *****************
    function getSettlableToken(uint256 boxId) public view returns (uint256) {
        address components = MurmesInterface(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.platform == Lens, "LA66");
        uint256 profileId = boxLensItemMap[box.id].profileId;
        uint256 pubId = boxLensItemMap[box.id].pubId;
        address module = ILensHub(Lens).getCollectModule(profileId, pubId);
        uint256 amount = ILensFeeModuleForMurmes(module)
            .getTotalRevenueForMurmes(profileId, pubId);
        uint256 increase = amount > boxLensItemMap[box.id].revenue
            ? amount - boxLensItemMap[box.id].revenue
            : 0;
        return increase;
    }

    function getLensItem(
        uint256 realId
    ) external view returns (LensItem memory) {
        return boxLensItemMap[realId];
    }

    function isModuleWhitelisted(address module) external view returns (bool) {
        return whitelistedLensModule[module];
    }
}
