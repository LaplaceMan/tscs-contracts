// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../common/token/ERC721/IERC721.sol";

interface IST is IERC721 {
    function mintST(
        address maker,
        uint256 applyId,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256);

    function getSTFingerprint(uint256 tokenId) external view returns (uint256);
}
