// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./common/token/ERC1155/ERC1155.sol";
import "./common/utils/Ownable.sol";
import "./interfaces/IVT.sol";

contract VideoToken is ERC1155, Ownable, IVT {
    address public subtitleSystem;

    mapping(uint256 => address) platform;
    mapping(uint256 => string) suffix;

    constructor(address ss) ERC1155("VideoToken") {
        subtitleSystem = ss;
        _setOwner(ss);
        suffix[0] = "Default";
        platform[0] = ss;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function tokenUri(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory baseURI = uri(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "-", suffix[tokenId]))
                : "";
    }

    function createPlatformToken(
        string memory symbol,
        address endorser,
        uint256 platformId
    ) external override onlyOwner {
        require(platform[platformId] == address(0), "Already Joined");
        platform[platformId] = endorser;
        suffix[platformId] = symbol;
    }

    function mintStableToken(
        uint256 platformId,
        address to,
        uint256 amount
    ) external override auth {
        require(platform[platformId] == address(0), "Already Joined");
        _mint(to, platformId, amount, "");
    }

    function divide(
        uint256 platformId,
        address from,
        address to,
        uint256 amount
    ) external override auth {
        require(platform[platformId] == address(0), "Already Joined");
        _safeTransferFrom(from, to, platformId, amount, "");
    }
}
