// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IMurmes.sol";
import "../interfaces/IPlatforms.sol";
import "../interfaces/IComponentGlobal.sol";
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
     * @notice 请求和Box ID的映射
     */
    mapping(bytes32 => uint256) public requestBoxIdMap;
    /**
     * @notice 请求和任务ID的映射
     */
    mapping(bytes32 => uint256) public requestTaskIdMap;
    /**
     * @notice Box ID和Box收益的映射
     */
    mapping(uint256 => uint256) public boxRevenue;

    event RequestUpdateBoxRevenue(
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
     * @notice 提交更新特定Box收益的申请
     * @param boxId 根据注册顺序获得的Box ID
     * @return requestId Chainlink 请求ID
     * Fn 1
     */
    function requestUpdateBoxRevenue(
        uint256 boxId
    ) public returns (bytes32 requestId) {
        address components = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        DataTypes.BoxStruct memory box = IPlatforms(platforms).getBox(boxId);
        require(box.platform == address(this), "PK15");

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillUpdateBoxRevenue.selector
        );

        string memory api = string(
            abi.encodePacked("/getBoxRevenueAPI/", boxId)
        );

        req.add("get", api);
        req.add("path", "0,counts");
        requestId = sendChainlinkRequest(req, fee);
        requestBoxIdMap[requestId] = boxId;
        return requestId;
    }

    /**
     * @notice Chainlink 返回特定视频ID的播放量
     * @param _requestId Chainlink 申请ID
     * @param _counts 根据平台提供的API返回的特定视频最新的播放量
     * Fn 2
     */
    function fulfillUpdateBoxRevenue(
        bytes32 _requestId,
        uint256 _counts
    ) public recordChainlinkFulfillment(_requestId) {
        uint256 boxId = requestBoxIdMap[_requestId];
        bool result = _updateBoxRevenue(boxId, _counts);
        emit RequestUpdateBoxRevenue(_requestId, _counts, result);
    }

    /**
     * @notice 由平台方提供服务，使用数字签名的方式更新Box收益
     * @return result 更新结果
     * Fn 3
     */
    function updateBoxRevenueWithSignature(
        uint256 boxId,
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
                    abi.encode(UPDATEVIDEOVIEWCOUNTS_TYPEHASH, boxId, counts)
                )
            )
        );
        require(_checkSignature(digest, v, r, s), "PK35");
        result = _updateBoxRevenue(boxId, counts);
    }

    /**
     * @notice 内部功能，调用Murmes协议updateBoxesRevenue更新Box收益
     * Fn 4
     */
    function _updateBoxRevenue(
        uint256 _id,
        uint256 _counts
    ) internal returns (bool) {
        if (_counts > boxRevenue[_id]) {
            uint256[] memory update = new uint256[](1);
            update[0] = _counts - boxRevenue[_id];
            uint256[] memory id = new uint256[](1);
            id[0] = _id;
            boxRevenue[_id] = _counts;
            address components = IMurmes(Murmes).componentGlobal();
            address platforms = IComponentGlobal(components).platforms();
            IPlatforms(platforms).updateBoxesRevenue(id, update);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice 由平台方提供服务，使用数字签名的方式创建Box和创作者的映射关系
     * @return boxId 根据注册顺序获得的在Murmes中的Box ID
     * Fn 5
     */
    function openServiceForBoxWithSignature(
        uint256 realId,
        address creator,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 boxId) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(OPENSERVICEFORVIDEO_TYPEHASH, realId, creator)
                )
            )
        );
        require(_checkSignature(digest, v, r, s), "PK55");
        boxId = _openMurmesServiceForBox(realId, creator);
    }

    /**
     * @notice 由平台Platform注册Box, 此后该Box支持链上结算
     * @param realId Box在Platform内部的 ID
     * @param creator Box创作者区块链地址
     * Fn 6
     */
    function openServiceForVideo(
        uint256 realId,
        address creator
    ) external onlyOwner returns (uint256 boxId) {
        boxId = _openMurmesServiceForBox(realId, creator);
    }

    /**
     * @notice 内部功能，调用Murmes协议createBox创建Box和创作者的映射关系
     * Fn 7
     */
    function _openMurmesServiceForBox(
        uint256 id,
        address creator
    ) internal returns (uint256) {
        address components = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        uint256 boxId = IPlatforms(platforms).createBox(
            id,
            address(this),
            creator
        );
        return boxId;
    }

    /**
     * @notice 内部功能，检查签名有效性
     * Fn 8
     */
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
     * @notice 修改自己Platform内的比率
     * @param rateCountsToProfit 新的收益转换率
     * @param rateAuditorDivide 新的审核分成率
     * Fn 9
     */
    function setPlatfromRate(
        uint16 rateCountsToProfit,
        uint16 rateAuditorDivide
    ) external onlyOwner {
        address components = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        IPlatforms(platforms).setPlatformRate(
            rateCountsToProfit,
            rateAuditorDivide
        );
    }

    /**
     * @notice 提取合约内未用尽的link代币
     * Fn 10
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
