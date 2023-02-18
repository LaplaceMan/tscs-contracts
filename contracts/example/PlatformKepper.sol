/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2023-02-01 11:59:41
 * @Description 提供了一种使用 Chainlink API调用服务和数字签名的方式完成平台的维护的例子，包括视频播放量、字幕使用量更新，为视频开启Murmes使用权限（链上结算方式和抵押支付策略），必要比率设置，减轻了平台负担，利益相关者可根据需要调用更新功能，
 * @Copyright (c) 2023 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IMurmes.sol";
import "../interfaces/IPlatform.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract PlatformKepper is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    // Chainlink 配置相关
    bytes32 private jobId;
    uint256 private fee;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("UpdateVideoViewCountsWithSignature(uint256 videoId, uint256 counts)");
    bytes32 private constant UPDATEVIDEOVIEWCOUNTS_TYPEHASH =
        0x5b357a9f17b9905df19f6102051478d3931912e01d42f30fae30f86e220dc6f0;
    // keccak256("UpdateSubtitleUsageCountsWithSignature(uint256 videoId, uint256 counts)");
    bytes32 private constant UPDATESUBTITLEUSAGECOUNTS_TYPEHASH =
        0x5a4c4f64f189674a02d0335b24fd3c877cbf501565ce623ed2dc590bfbac0278;
    // keccak256("OpenServiceForVideo(uint256 realId, string symbol, address creator, uint256 initialize)");
    bytes32 private constant OPENSERVICEFORVIDEO_TYPEHASH =
        0x9be7644ff53e43aec03869bd1faa073bff6d9f3d7cecb06f9523f721a75b8341;
    /**
     * @notice Murmes 主合约地址
     */
    address public Murmes;
    /**
     * @notice 请求和视频ID的映射
     */
    mapping(bytes32 => uint256) public requestVideoIdMap;
    /**
     * @notice 请求和申请（任务）ID的映射
     */
    mapping(bytes32 => uint256) public requestApplyIdMap;
    /**
     * @notice 申请ID和字幕最新使用量的映射
     */
    mapping(uint256 => uint256) public latestSubtitleUsage;

    event RequestUpdateVideoViewCounts(
        bytes32 indexed requestId,
        uint256 counts,
        bool result
    );

    event RequestUpdateSubtitleUsageCounts(
        bytes32 indexed requestId,
        uint256 counts,
        bool result
    );

    /**
     * @notice Chainlink 配置和 Murmes 主合约地址初始化
     */
    constructor(address ms) ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10;
        Murmes = ms;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(uint256 chainId,address muremes,address verifyingContract)"
                ),
                chainId,
                ms,
                address(this)
            )
        );
    }

    /**
     * @notice 提交更新特定视频播放量的申请
     * @param videoId 根据注册顺序获得的视频ID
     * @return requestId Chainlink 请求ID
     * label PK1
     */
    function requestVideoViewCounts(uint256 videoId)
        public
        returns (bytes32 requestId)
    {
        address platforms = IMurmes(Murmes).platforms();
        (address platform, , , , , , ) = IPlatform(platforms).getVideoBaseInfo(
            videoId
        );
        require(platform == address(this), "PK1-5");

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillVideoViewCounts.selector
        );

        string memory api = string(
            abi.encodePacked("/getVideoViewCountsAPI/", videoId)
        );

        req.add("get", api);
        req.add("path", "0,counts");
        requestId = sendChainlinkRequest(req, fee);
        requestVideoIdMap[requestId] = videoId;
        return requestId;
    }

    /**
     * @notice 提交更新特定字幕使用量的申请
     * @param applyId 字幕所属的申请ID
     * @return requestId Chainlink 请求ID
     */
    // function requestSubtitleUsageCounts(uint256 applyId)
    //     public
    //     returns (bytes32 requestId)
    // {
    //     (, address platform, , , , , , , , ) = IMurmes(Murmes).tasks(applyId);
    //     require(platform == address(this), "ER5");

    //     Chainlink.Request memory req = buildChainlinkRequest(
    //         jobId,
    //         address(this),
    //         this.fulfillSubtitleUsageCounts.selector
    //     );

    //     string memory api = string(
    //         abi.encodePacked("/getSubtitleUsageCountsAPI/", applyId)
    //     );

    //     req.add("get", api);
    //     req.add("path", "0,counts");
    //     requestId = sendChainlinkRequest(req, fee);
    //     requestApplyIdMap[requestId] = applyId;
    //     return requestId;
    // }

    /**
     * @notice 内部功能，调用Murmes协议 updateViewCounts 更新视频播放量
     * label PK2
     */
    function _updateVideoViewCounts(uint256 _id, uint256 _counts)
        internal
        returns (bool)
    {
        address platforms = IMurmes(Murmes).platforms();
        (, , , , uint256 counts, , ) = IPlatform(platforms).getVideoBaseInfo(
            _id
        );
        if (_counts > counts) {
            uint256[] memory update = new uint256[](1);
            update[0] = _counts - counts;
            uint256[] memory id = new uint256[](1);
            id[0] = _id;
            IPlatform(platforms).updateViewCounts(id, update);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice 内部功能，调用Murmes协议 updateUsageCounts 更新字幕使用量
     */
    // function _updateSubtitleUsageCounts(uint256 _id, uint256 _counts)
    //     internal
    //     returns (bool)
    // {
    //     uint256 latestUsage = latestSubtitleUsage[_id];
    //     latestSubtitleUsage[_id] = _counts;
    //     if (_counts - latestUsage > 0) {
    //         uint256[] memory update = new uint256[](1);
    //         update[0] = _counts;
    //         uint256[] memory id = new uint256[](1);
    //         id[0] = _id;
    //         IMurmes(Murmes).updateUsageCounts(id, update);
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }

    /**
     * @notice 内部功能，调用Murmes协议 createVideo 创建视频和创作者的映射关系
     * label PK3
     */
    function _openMurmesServiceForVideo(
        uint256 id,
        string memory symbol,
        address creator,
        uint256 initialize
    ) internal returns (uint256) {
        address platforms = IMurmes(Murmes).platforms();
        uint256 videoId = IPlatform(platforms).createVideo(
            id,
            symbol,
            creator,
            initialize,
            address(0)
        );
        return videoId;
    }

    // 内部辅助功能，检查签名有效性
    // label PK4
    function _checkSignature(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress != address(0) && recoveredAddress == owner()) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Chainlink 返回特定视频ID的播放量
     * @param _requestId Chainlink 申请ID
     * @param _counts 根据平台提供的API返回的特定视频最新的播放量
     * label PK5
     */
    function fulfillVideoViewCounts(bytes32 _requestId, uint256 _counts)
        public
        recordChainlinkFulfillment(_requestId)
    {
        uint256 videoId = requestVideoIdMap[_requestId];
        bool result = _updateVideoViewCounts(videoId, _counts);
        emit RequestUpdateVideoViewCounts(_requestId, _counts, result);
    }

    /**
     * @notice  Chainlink 返回特定申请ID下被采纳字幕的使用量
     * @param _requestId Chainlink 请求ID
     * @param _counts 根据平台提供的API返回的特定字幕最新的使用量
     */
    // function fulfillSubtitleUsageCounts(bytes32 _requestId, uint256 _counts)
    //     public
    //     recordChainlinkFulfillment(_requestId)
    // {
    //     uint256 applyId = requestApplyIdMap[_requestId];
    //     bool result = _updateSubtitleUsageCounts(applyId, _counts);
    //     emit RequestUpdateSubtitleUsageCounts(_requestId, _counts, result);
    // }

    /**
     * @notice 由平台方提供服务，使用数字签名的方式更新视频播放量
     * @return result 更新结果
     * label PK6
     */
    function updateVideoViewCountsWithSignature(
        uint256 videoId,
        uint256 counts,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool result) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(UPDATEVIDEOVIEWCOUNTS_TYPEHASH, videoId, counts)
                )
            )
        );
        require(_checkSignature(digest, v, r, s), "PK6-5");
        result = _updateVideoViewCounts(videoId, counts);
    }

    /**
     * @notice 由平台方提供服务，使用数字签名的方式更新字幕使用量
     * @return result 更新结果
     */
    // function updateSubtitleUsageCountsWithSignature(
    //     uint256 applyId,
    //     uint256 counts,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (bool result) {
    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             "\x19\x01",
    //             DOMAIN_SEPARATOR,
    //             keccak256(
    //                 abi.encode(
    //                     UPDATESUBTITLEUSAGECOUNTS_TYPEHASH,
    //                     applyId,
    //                     counts
    //                 )
    //             )
    //         )
    //     );
    //     require(_checkSignature(digest, v, r, s), "ER5");
    //     result = _updateSubtitleUsageCounts(applyId, counts);
    // }

    /**
     * @notice 由平台方提供服务，使用数字签名的方式创建视频和创作者的映射关系
     * @return videoId 根据注册顺序获得的在 Murmes 中的视频ID
     * label PK7
     */
    function openServiceForVideoWithSignature(
        uint256 realId,
        string memory symbol,
        address creator,
        uint256 initialize,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 videoId) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        OPENSERVICEFORVIDEO_TYPEHASH,
                        realId,
                        symbol,
                        creator,
                        initialize
                    )
                )
            )
        );
        require(_checkSignature(digest, v, r, s), "PK7-5");
        videoId = _openMurmesServiceForVideo(
            realId,
            symbol,
            creator,
            initialize
        );
    }

    /**
     * @notice 由平台 Platform 注册视频, 此后该视频支持链上结算（意味着更多结算策略的支持）
     * @param realId 视频在 Platform 内部的 ID
     * @param symbol 视频的 symbol
     * @param creator 视频创作者区块链地址
     * @param initialize 初始化时（开启服务前）视频播放量
     * @return videoId 视频在 Murmes 内的 ID
     * label PK8
     */
    function openServiceForVideo(
        uint256 realId,
        string memory symbol,
        address creator,
        uint256 initialize
    ) external onlyOwner returns (uint256 videoId) {
        videoId = _openMurmesServiceForVideo(
            realId,
            symbol,
            creator,
            initialize
        );
    }

    /**
     * @notice 修改自己 Platform 内的比率, 请至少保证一个非 0, 避免无效修改
     * @param rateCountsToProfit 播放量和实际收益比例
     * @param rateAuditorDivide 字幕支持者分成比例
     * label PK9
     */
    function setPlatfromRate(
        uint16 rateCountsToProfit,
        uint16 rateAuditorDivide
    ) external onlyOwner {
        address platforms = IMurmes(Murmes).platforms();
        IPlatform(platforms).platformRate(
            rateCountsToProfit,
            rateAuditorDivide
        );
    }

    /**
     * @notice 提取合约内未用尽的 link 代币
     * label PK10
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
