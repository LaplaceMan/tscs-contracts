// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC721/ERC721.sol";

contract SubtitleManager is ERC721 {
    
    mapping(uint256 => Subtitle) subtitleNFT;
    
    struct Subtitle {
        address platfrom;
        string language;
        uint8 state;
        uint256 support;
        uint256 opposition;
        address[] supporters;
        address[] protecter;
    }


}
