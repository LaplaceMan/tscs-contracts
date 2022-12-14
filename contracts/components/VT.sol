/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-09-09 16:45:13
 * @Description: 由平台 Platform 背书的 ERC1155 稳定币, tokenId 与 platformId 对应
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/token/ERC1155/ERC1155.sol";
import "../interfaces/IVT.sol";

contract VideoToken is ERC1155, IVT {
    /**
     * @notice Murmes 合约地址
     */
    address public Murmes;
    /**
     * @notice 拥有特殊权限的地址，一般为 DAO 合约
     */
    address public opeator;
    /**
     * @notice ERC1155 中不同 Token ID 的 Token URI 的后缀
     */
    mapping(uint256 => string) suffix;
    /**
     * @notice ERC1155 Token ID 与所属平台 Platform 区块链地址的映射
     */
    mapping(uint256 => address) platform;

    event SystemChangeOpeator(address newOpeator);
    /**
     * @notice 仅能由 opeator 调用
     */
    modifier onlyOwner() {
        require(msg.sender == opeator, "ER5");
        _;
    }
    /**
     * @notice 仅能由 Murmes 调用
     */
    modifier auth() {
        require(msg.sender == Murmes, "ER5");
        _;
    }

    event PlatformToken(address platform, uint256 id);

    constructor(address ms) ERC1155("VideoToken") {
        Murmes = ms;
        suffix[0] = "Default";
        platform[0] = ms;
    }

    /**
     * @notice ERC1155 不同 Token ID 的精度都为 6
     * @return 返回 Token 精度
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @notice 通过 URI 区分由不同平台 Platform 背书的稳定币, 同时符合 ERC1155 标准
     * @param tokenId Token ID, 与平台 Platform 在 Murmes 内的 ID 对应
     * @return 返回 ERC1155 不同 Token 的 URI
     */
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

    /**
     * @notice 当新平台 Platform 加入 Murmes 时, 同时生成由其背书的稳定币（用来结算）
     * @param symbol 平台 Platform 加入时设置的 symbol
     * @param endorser 为发行的稳定币背书, 实际上就是平台 Platform 区块链地址
     * @param platformId 平台 Platform 在 Murmes 内的 ID
     */
    function createPlatformToken(
        string memory symbol,
        address endorser,
        uint256 platformId
    ) external override onlyOwner {
        require(platform[platformId] == address(0), "ER0");
        platform[platformId] = endorser;
        suffix[platformId] = symbol;
        emit PlatformToken(endorser, platformId);
    }

    /**
     * @notice 为用户在相应平台 Platform 铸造稳定币
     * @param platformId 平台 Platform 在 Murmes 内的 ID
     * @param to 稳定币接收方
     * @param amount 接收由相应平台发行并背书的稳定币数量
     */
    function mintStableToken(
        uint256 platformId,
        address to,
        uint256 amount
    ) external override auth {
        require(platform[platformId] != address(0), "ER2");
        _mint(to, platformId, amount, "");
    }

    /**
     * @notice 销毁用户在平台 Platform 的稳定币
     * @param platformId 平台 Platform 在 Murmes 内的 ID
     * @param from 支出稳定币的一方
     * @param amount 支出稳定币数目
     */
    function burnStableToken(
        uint256 platformId,
        address from,
        uint256 amount
    ) external override {
        require(platform[platformId] != address(0), "ER2");
        if (msg.sender != Murmes) {
            require(msg.sender == from, "ER5");
        }
        _burn(from, platformId, amount);
    }

    /**
     * @notice 更改拥有特殊权限的操作员地址
     * @param newOpeator 更换 DAO 合约地址
     */
    function changeOpeator(address newOpeator) external {
        require(msg.sender == opeator || msg.sender == Murmes, "ER5");
        opeator = newOpeator;
        emit SystemChangeOpeator(newOpeator);
    }
}
