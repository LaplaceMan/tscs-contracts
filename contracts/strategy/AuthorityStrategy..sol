// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IPlatform.sol";
import {ILensHub} from "../interfaces/ILensHub.sol";
import "../interfaces/IMurmes.sol";
import "../interfaces/IAuthorityStrategy.sol";
import "../interfaces/ILensFeeModuleForMurmes.sol";

contract AuthorityStrategy is IAuthorityStrategy {
    address public Lens;
    address public Murmes;

    mapping(uint256 => uint16) occupied;

    mapping(uint256 => LensVideo) videoLensMap;

    mapping(address => bool) whitelistedModule;

    struct LensVideo {
        uint256 profileId;
        uint256 pubId;
        uint256 income;
    }

    function isOwnApplyAuthority(
        address platform,
        uint256 videoId,
        string memory source,
        address caller,
        uint8 strategy,
        uint256 amount
    ) external {
        require(msg.sender == Murmes, "ER5");
        if (strategy == 1) {
            require(uint16(amount) + occupied[videoId] < 58981, "ER1");
            occupied[videoId] += uint16(amount);
        }
        if (platform == Murmes) {
            require(strategy == 0, "ER7");
            require(bytes(source).length > 0, "ER7-2");
        } else if (platform == Lens) {
            (uint256 profileId, bool result) = _stringToUint256(source);
            require(result, "ER1");
            address owner = ILensHub(Lens).ownerOf(profileId);
            require(owner == caller, "ER5-2");
            uint256 realId = uint256(keccak256(abi.encode(profileId, videoId)));
            address platforms = IMurmes(Murmes).platforms();
            uint256 orderId = IPlatform(platforms).getVideoOrderIdByRealId(
                platform,
                realId
            );
            {
                address module = ILensHub(Lens).getCollectModule(
                    profileId,
                    videoId
                );
                require(whitelistedModule[module] = true, "ER5");
            }
            if (orderId > 0) {
                (, , , address creator, , , ) = IPlatform(platforms)
                    .getVideoBaseInfo(videoId);
                require(caller == creator, "ER5-2");
            } else {
                // 可以记录此刻pub的收藏收入，使得结算更加精确，贡献者只能获得申请发布后的部分
                IPlatform(platforms).createVideo(
                    realId,
                    string(abi.encodePacked(source, "-", videoId)),
                    caller,
                    0
                );
                videoLensMap[realId].profileId = profileId;
                videoLensMap[realId].pubId = videoId;
            }
        } else {
            (, , , address creator, , , ) = IPlatform(platform)
                .getVideoBaseInfo(videoId);
            require(creator == caller, "ER5-2");
        }
    }

    function isOwnCreateVideoAuthority(uint256 flag, address caller)
        external
        view
    {
        if (caller != Lens) {
            require(flag > 0, "ER5");
        } else {
            require(IMurmes(caller).isOperator(caller), "ER5");
        }
    }

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
            require(whitelistedModule[module] = true, "ER5");
            uint256 amount = ILensFeeModuleForMurmes(module).getTotalIncome(
                profileId,
                pubId
            );
            return amount;
        } else {
            require(platform == caller, "ER5");
            return counts;
        }
    }

    function _stringToUint256(string memory str)
        internal
        pure
        returns (uint256 value, bool result)
    {
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (
                (uint8(bytes(str)[i]) - 48) < 0 ||
                (uint8(bytes(str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            value +=
                (uint8(bytes(str)[i]) - 48) *
                10**(bytes(str).length - i - 1);
        }
        return (value, true);
    }
}
