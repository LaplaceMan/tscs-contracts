// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../common/token/ERC721/IERC721.sol";

interface IItemNFT is IERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintItemToken(
        address maker,
        uint256 taskId,
        string memory cid,
        uint256 requireId,
        uint256 fingerprint
    ) external returns (uint256);

    function getItemFingerprint(uint256 tokenId)
        external
        view
        returns (uint256);

    function getItemBaseInfo(uint256 subtitleId)
        external
        view
        returns (
            address,
            uint256,
            uint32,
            uint256
        );
}
