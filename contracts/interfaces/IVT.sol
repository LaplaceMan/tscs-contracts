// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC1155/IERC1155.sol";

interface IVT is IERC1155 {
    function Murmes() external returns (address);

    function decimals() external view returns (uint8);

    function tokenUri(uint256 tokenId) external view returns (string memory);

    function createPlatformToken(
        string memory symbol,
        address endorser,
        uint256 platformId
    ) external;

    function mintStableToken(
        uint256 platformId,
        address to,
        uint256 amount
    ) external;

    function burn(
        address from,
        uint256 platformId,
        uint256 amount
    ) external;
}
