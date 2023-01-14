/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-11-21 14:33:27
 * @Description: Murmes 内的 字幕代币合约，每个上传的字幕都会生成相应的 ERC-721 代币
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IST.sol";
import "../common/token/ERC721/ERC721.sol";

contract SubtitleToken is ERC721, IST {
    /**
     * @notice Murmes 主合约地址
     */
    address public Murmes;
    /**
     * @notice ERC721 代币 ID 顺位
     */
    uint256 private _tokenIdTracker;
    /**
     * @notice Mapping from token ID to storage address
     */
    mapping(uint256 => string) private _tokenURI;

    /***
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, IST)
        returns (string memory)
    {
        _requireMinted(tokenId);
        return _tokenURI[tokenId];
    }

    /**
     * @notice 每个字幕 ST 在生成时都会初始化相应的 Subtitle 结构
     * @param maker 字幕制作者
     * @param taskId 该字幕所属的申请
     * @param languageId 该字幕的语言
     * @param fingerprint 此处为字幕的 Simhash 指纹，用户相似度计算
     */
    struct Subtitle {
        address maker;
        uint256 taskId;
        uint16 languageId;
        uint256 fingerprint;
    }
    /**
     * @notice 每个字幕都会拥有相应的 Subitle 结构, 记录源信息
     */
    mapping(uint256 => Subtitle) subtitleNFT;

    constructor(address ms) {
        Murmes = ms;
    }

    event SubtitleUpload(
        address maker,
        uint256 taskId,
        uint256 subtitleId,
        string cid,
        uint16 languageId,
        uint256 fingerprint
    );

    /**
     * @notice 创建 ST, 内部功能
     * @param maker 字幕制作者区块链地址
     * @param taskId 字幕所属申请的 ID
     * @param cid 字幕存储在 IPFS 获得的 CID
     * @param languageId 字幕所属语种的 ID
     * @param fingerprint 字幕指纹, 此处暂定为 Simhash
     * @return 字幕代币 ST（Subtitle Token） ID
     */
    function mintST(
        address maker,
        uint256 taskId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) external override returns (uint256) {
        require(msg.sender == Murmes, "ER5");
        _tokenIdTracker++;
        _mint(maker, _tokenIdTracker);
        _tokenURI[_tokenIdTracker] = cid;
        subtitleNFT[_tokenIdTracker].maker = maker;
        subtitleNFT[_tokenIdTracker].taskId = taskId;
        subtitleNFT[_tokenIdTracker].languageId = languageId;
        subtitleNFT[_tokenIdTracker].fingerprint = fingerprint;
        emit SubtitleUpload(
            maker,
            taskId,
            _tokenIdTracker,
            cid,
            languageId,
            fingerprint
        );
        return _tokenIdTracker;
    }

    /**
     * @notice 获得字幕的指纹值
     * @param tokenId 字幕的 ID
     * @return 返回特定字幕的指纹值
     */
    function getSTFingerprint(uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return subtitleNFT[tokenId].fingerprint;
    }

    /**
     * @notice 获得字幕代币 ST 的基本信息
     * @param subtitleId ST ID
     * @return 获得字幕代币ST 的拥有者、所属的申请、语言类型和哈希指纹
     */
    function getSTBaseInfo(uint256 subtitleId)
        external
        view
        override
        returns (
            address,
            uint256,
            uint16,
            uint256
        )
    {
        return (
            subtitleNFT[subtitleId].maker,
            subtitleNFT[subtitleId].taskId,
            subtitleNFT[subtitleId].languageId,
            subtitleNFT[subtitleId].fingerprint
        );
    }
}
