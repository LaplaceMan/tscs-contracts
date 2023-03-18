// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IPlatformToken.sol";
import "../common/token/ERC1155/ERC1155.sol";

interface MurmesInterface {
    function isOperator(address caller) external view returns (bool);
}

contract PlatformToken is ERC1155, IPlatformToken {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 标记Token类型的文本后缀
     */
    mapping(uint256 => string) suffix;
    /**
     * @notice 第三方平台的标志性地址
     */
    mapping(uint256 => address) platforms;

    constructor(address ms) ERC1155("PlatformToken") {
        Murmes = ms;
        suffix[0] = "Murmes";
        platforms[0] = ms;
    }

    /**
     * @notice 当新平台加入Murmes时, 同时生成由其背书的用来结算的代币
     * @param symbol 平台加入时设置的标识
     * @param endorser 为发行的代币背书, 实际上就是平台区块链地址
     * @param platformId 平台在Murmes内的ID
     * Fn 1
     */
    function createPlatformToken(
        string memory symbol,
        address endorser,
        uint256 platformId
    ) external override {
        require(platforms[platformId] == address(0), "PT10");
        require(MurmesInterface(Murmes).isOperator(msg.sender), "PT15");
        platforms[platformId] = endorser;
        suffix[platformId] = symbol;
        emit CreatePlatformToken(endorser, platformId);
    }

    /**
     * @notice 为用户在相应平台铸造代币
     * @param platformId 平台在Murmes内的ID
     * @param to 代币接收方
     * @param amount 接收由相应平台发行并背书的代币数量
     * Fn 2
     */
    function mintPlatformTokenByMurmes(
        uint256 platformId,
        address to,
        uint256 amount
    ) external override {
        require(msg.sender == Murmes, "PT25");
        require(platforms[platformId] != address(0), "PT22");
        _mint(to, platformId, amount, "");
    }

    /**
     * @notice 销毁用户在平台内的代币
     * @param platformId 平台在Murmes内的 ID
     * @param account 支出代币的一方
     * @param value 支出代币数目
     * Fn 3
     */
    function burn(
        address account,
        uint256 platformId,
        uint256 value
    ) external override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "PT35"
        );

        _burn(account, platformId, value);
    }

    // ***************** View Functions *****************
    function decimals() external pure override returns (uint8) {
        return 6;
    }

    function tokenUri(
        uint256 tokenId
    ) external view override returns (string memory) {
        string memory baseURI = uri(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "-", suffix[tokenId]))
                : "";
    }
}
