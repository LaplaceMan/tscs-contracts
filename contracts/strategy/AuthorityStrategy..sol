/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2023-02-14 16:58:15
 * @Description 与 Lens 结合的中间件
 * @Copyright (c) 2023 by LaplaceMan, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/IPlatform.sol";
import {ILensHub} from "../interfaces/ILensHub.sol";
import "../interfaces/IMurmes.sol";
import "../interfaces/IAuthorityStrategy.sol";
import "../interfaces/ILensFeeModuleForMurmes.sol";
import "../common/token/ERC1155/IERC1155.sol";
import "../common/token/ERC20/IERC20.sol";

contract AuthorityStrategy is IAuthorityStrategy {
    /**
     * @notice Lens Hub 合约地址
     */
    address public immutable Lens;

    /**
     * @notice Murmes 主合约地址
     */
    address public immutable Murmes;

    /**
     * @notice 在使用分成结算策略时，一个视频的总分成不能超过百分之80，这是为了保证同视频下使用一次性支付下的的字幕制作者权益
     */
    uint16 constant MAX_TOTAL_DIVIDED = 39321;

    mapping(uint256 => uint16) occupied;

    /**
     * @notice 对视频ID 和 Lens 资产做映射
     */
    mapping(uint256 => LensVideo) videoLensMap;

    /**
     * @notice 白名单内的Lens上的Module
     */
    mapping(address => bool) whitelistedLensModule;

    event SetWhitelistedLensModule(address module, bool usability);

    constructor(address ms, address lens) {
        Lens = lens;
        Murmes = ms;
    }

    /**
     * @notice 用于Lens资产和Murmes中视频的映射
     * @param profileId profileId
     * @param pubId pubId
     * @param income 发出申请后Lens视频通过collect获得的收益
     */
    struct LensVideo {
        uint256 profileId;
        uint256 pubId;
        uint256 income;
    }

    /**
     * @notice 判断调用者的申请权限，但支付策略非普通的一次性结算时
     * @param platform 所属平台地址
     * @param videoId realId 视频在平台内的 ID，在Lens下为pubId
     * @param source 视频源地址，Lens下为 profileId
     * @param caller 调用者
     * @param strategy 结算策略
     * @param amount 支付数量/比例
     */
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
            require(
                uint16(amount) + occupied[videoId] < MAX_TOTAL_DIVIDED,
                "ER1"
            );
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
            address module = ILensHub(Lens).getCollectModule(
                profileId,
                videoId
            );
            require(whitelistedLensModule[module] = true, "ER5");
            uint256 realId = uint256(keccak256(abi.encode(profileId, videoId)));
            address platforms = IMurmes(Murmes).platforms();
            uint256 orderId = IPlatform(platforms).getVideoOrderIdByRealId(
                platform,
                realId
            );

            if (orderId == 0) {
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
            address platforms = IMurmes(Murmes).platforms();
            (, , , address creator, , , ) = IPlatform(platforms)
                .getVideoBaseInfo(videoId);
            require(creator == caller, "ER5-2");
        }
    }

    /**
     * @notice 判断调用者是否有创建视频的权限
     * @param flag rateCountsToProfit 判断平台的有效性
     * @param caller 调用者
     */
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

    /**
     * @notice 判断调用者是否有更新视频播放量/收益的权限
     * @param realId 视频（在第三方平台内）的真实 ID
     * @param counts 播放量
     * @param platform 第三方平台地址
     * @param caller 调用者
     * @return 可更新的播放量/收益
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
            require(whitelistedLensModule[module] = true, "ER5");
            uint256 amount = ILensFeeModuleForMurmes(module)
                .getTotalIncomeForMurmes(profileId, pubId);
            uint256 increase = amount - videoLensMap[realId].income;
            videoLensMap[realId].income = amount;
            return increase;
        } else {
            require(platform == caller, "ER5");
            return counts;
        }
    }

    /**
     * @notice 使用相应的VT兑换Lens作品的创作者的收益
     * @param amount 欲兑换数量，保持1:1
     */
    function swapInLens(uint256 amount) external {
        address platforms = IMurmes(Murmes).platforms();
        uint256 tokenId = IPlatform(platforms).getPlatformIdByAddress(Lens);
        address token = IPlatform(platforms).tokenGlobal();
        address vt = IMurmes(Murmes).videoToken();
        IERC1155(vt).safeTransferFrom(
            msg.sender,
            address(0),
            tokenId,
            amount,
            ""
        );
        require(
            IERC20(token).transferFrom(address(this), msg.sender, amount),
            "ER12"
        );
    }

    /**
     * @notice 设置Murmes兼容的在Lens中的Module
     * @param module collectModule 地址
     * @param usability 可用性
     */
    function setWhitelistedLensModule(address module, bool usability) external {
        whitelistedLensModule[module] = usability;
        emit SetWhitelistedLensModule(module, usability);
    }

    /**
     * @notice 内部功能，string 转 uint256
     */
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
