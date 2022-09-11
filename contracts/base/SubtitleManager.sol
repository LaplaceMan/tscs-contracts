// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC721/ERC721.sol";

contract SubtitleManager is ERC721 {
    uint256 private _tokenIdTracker;
    mapping(uint256 => Subtitle) subtitleNFT;
    mapping(address => mapping(uint256 => bool)) evaluated;

    struct Subtitle {
        uint256 applyId;
        uint16 languageId;
        uint256 fingerprint;
        uint8 state;
        uint256 stateChangeTime;
        address[] supporters;
        address[] dissenter;
    }

    function _createST(
        address maker,
        uint256 applyId,
        uint16 languageId,
        uint256 fingerprint
    ) internal returns (uint256) {
        _tokenIdTracker++;
        _mint(maker, _tokenIdTracker);
        subtitleNFT[_tokenIdTracker].applyId = applyId;
        subtitleNFT[_tokenIdTracker].languageId = languageId;
        subtitleNFT[_tokenIdTracker].fingerprint = fingerprint;
        return _tokenIdTracker;
    }

    // 0 无变化 1 确认 2 删除
    function _changeST(uint256 id, uint8 state) internal {
        subtitleNFT[id].state = state;
        subtitleNFT[id].stateChangeTime = block.timestamp;
    }

    function _evaluateST(
        uint256 subtitleId,
        uint8 attitude,
        address evaluator
    ) internal {
        require(subtitleNFT[subtitleId].state == 0, "Treated");
        require(evaluated[evaluator][subtitleId] == false, "Evaluated");
        if (attitude == 0) {
            subtitleNFT[subtitleId].supporters.push(evaluator);
        } else {
            subtitleNFT[subtitleId].dissenter.push(evaluator);
        }
        evaluated[evaluator][subtitleId] = true;
    }
}
