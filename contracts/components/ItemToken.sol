// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IItemNFT.sol";
import "../common/token/ERC721/ERC721.sol";

contract ItemToken is ERC721, IItemNFT {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice Item Token总数
     */
    uint256 private _tokenIdTracker;
    /**
     * @notice Item Token的创作者，与所有者区分
     */
    mapping(uint256 => address) private _tokenCreator;
    /**
     * @notice Item的基本信息
     */
    mapping(uint256 => DataTypes.ItemMetadata) itemsNFT;

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 创建 Item NFT
     * @param maker Item制作者地址
     * @param vars Item信息
     * @return 包装后Item代币的ID
     * Fn 1
     */
    function mintItemTokenByMurmes(
        address maker,
        DataTypes.ItemMetadata calldata vars
    ) external override returns (uint256) {
        require(msg.sender == Murmes, "IT15");
        _tokenIdTracker++;
        _mint(maker, _tokenIdTracker);
        _tokenCreator[_tokenIdTracker] = maker;
        itemsNFT[_tokenIdTracker] = vars;
        return _tokenIdTracker;
    }

    // ***************** View Functions *****************
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, IItemNFT) returns (string memory) {
        _requireMinted(tokenId);
        return itemsNFT[tokenId].cid;
    }

    function getItemFingerprint(
        uint256 tokenId
    ) external view override returns (uint256) {
        return itemsNFT[tokenId].fingerprint;
    }

    function getItemBaseData(
        uint256 itemId
    ) external view override returns (address, uint256, uint256) {
        return (
            _tokenCreator[itemId],
            itemsNFT[itemId].taskId,
            itemsNFT[itemId].requireId
        );
    }
}
