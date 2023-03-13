// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IPlatforms.sol";
import "../interfaces/IAuthorityBase.sol";
import "../interfaces/IComponentGlobal.sol";
import "../interfaces/ILensFeeModuleForMurmes.sol";
import {ILensHub} from "../interfaces/ILensHub.sol";

interface MurmesInterface {
    function componentGlobal() external view returns (address);

    function owner() external view returns (address);
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
        uint256 income;
    }

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

    function setWhitelistedLensModule(address module, bool result) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "LA5");
        whitelistedLensModule[module] = result;
        emit SetWhitelistedLensModule(module, usability);
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
