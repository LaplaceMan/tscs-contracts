// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
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
    address public Murmes;

    address public Lens;

    mapping(uint256 => LensItem) boxLensItemMap;

    mapping(address => bool) whitelistedLensModule;

    event SetWhitelistedLensModule(address module, bool result);

    constructor(address ms, address lens) {
        Lens = lens;
        Murmes = ms;
    }

    struct LensItem {
        uint256 profileId;
        uint256 pubId;
        uint256 revenue;
    }

    // Fn 1
    function forPostTask(
        address platform,
        uint256 boxId,
        string memory source,
        address caller,
        DataTypes.SettlementType settlement
    ) external returns (uint256) {
        (uint256 profileId, bool result) = _stringToUint256(source);
        require(result, "LA11");
        address owner = ILensHub(Lens).ownerOf(profileId);
        require(owner == caller, "LA15");
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
            orderId = IPlatform(platforms).createBox(realId, Lens, caller);
            boxLensItemMap[realId].profileId = profileId;
            boxLensItemMap[realId].pubId = boxId;
        }
        return orderId;
    }

    // Fn 2
    function forCreateBox(
        address platform,
        uint256,
        address caller
    ) external returns (bool) {
        if (platform != Lens || !MurmesInterface(Murmes).isOperator(caller)) {
            return false;
        } else {
            return true;
        }
    }

    // Fn 3
    function forUpdateBoxRevenue(
        uint256 realId,
        uint256 counts,
        address platform,
        address caller
    ) external override returns (uint256) {
        uint256 profileId = boxLensItemMap[realId].profileId;
        uint256 pubId = boxLensItemMap[realId].pubId;
        address module = ILensHub(Lens).getCollectModule(profileId, pubId);
        require(whitelistedLensModule[module] = true, "LA35");
        uint256 amount = ILensFeeModuleForMurmes(module)
            .getTotalRevenueForMurmes(profileId, pubId);
        uint256 increase = amount > videoLensMap[realId].revenue
            ? amount - videoLensMap[realId].revenue
            : 0;
        videoLensMap[realId].revenue = amount;
        return increase;
    }

    // Fn 4
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

    // Fn 5
    function setWhitelistedLensModule(address module, bool result) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "LA65");
        whitelistedLensModule[module] = result;
        emit SetWhitelistedLensModule(module, usability);
    }

    // Fn 6
    function getSettlableToken(uint256 boxId) public view returns (uint256) {
        address components = MurmesInterface(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        DataTypes.BoxStruct memory box = IPlatform(paltforms).getBox(boxId);
        require(box.platform == Lens, "LA66");
        uint256 profileId = boxLensItemMap[realId].profileId;
        uint256 pubId = boxLensItemMap[realId].pubId;
        address module = ILensHub(Lens).getCollectModule(profileId, pubId);
        uint256 amount = ILensFeeModuleForMurmes(module)
            .getTotalRevenueForMurmes(profileId, pubId);
        uint256 increase = amount > boxLensItemMap[realId].revenue
            ? amount - boxLensItemMap[realId].revenue
            : 0;
        return increase;
    }

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
}
