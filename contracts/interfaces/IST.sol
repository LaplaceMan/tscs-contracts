// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../common/token/ERC721/IERC721.sol";

interface IST is IERC721 {
    function Murmes() external view returns (address);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mintST(
        address maker,
        uint256 taskId,
        string memory cid,
        uint16 languageId,
        uint256 fingerprint
    ) external returns (uint256);

    function getSTFingerprint(uint256 tokenId) external view returns (uint256);

    function getSTBaseInfo(uint256 subtitleId)
        external
        view
        returns (
            address,
            uint256,
            uint16,
            uint256
        );
}
