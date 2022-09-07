// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC721/ERC721.sol";

contract SubtitleManager is ERC721 {
    uint256 private _tokenIdTracker;
    mapping(uint256 => Subtitle) subtitleNFT;

    struct Subtitle {
        uint256 applyId;
        uint16 languageId;
        string fingerprint;
        uint8 state;
        address[] supporters;
        address[] dissenter;
    }

    function _createST(
        address maker,
        uint256 applyId,
        uint16 languageId,
        string memory fingerprint
    ) internal returns (uint256) {
        _tokenIdTracker++;
        _mint(maker, _tokenIdTracker);
        subtitleNFT[_tokenIdTracker].applyId = applyId;
        subtitleNFT[_tokenIdTracker].languageId = languageId;
        subtitleNFT[_tokenIdTracker].fingerprint = fingerprint;
        return _tokenIdTracker;
    }

    function _changeState(uint256 id, uint8 state) internal {
        subtitleNFT[id].state = state;
    }
}
