// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IPlatformToken.sol";
import "../common/token/ERC1155/ERC1155.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface MurmesInterface {
    function owner() external view returns (address);

    function isOperator(address caller) external view returns (bool);

    function componentGlobal() external view returns (address);

    function isEvaluated(
        address user,
        uint256 itemId
    ) external view returns (bool);

    function getTaskPublisher(uint256 taskId) external view returns (address);

    function getItem(
        uint256 itemId
    ) external view returns (DataTypes.ItemStruct memory);
}

interface ComponentInterface {
    function itemToken() external view returns (address);

    function lockUpTime() external view returns (uint256);
}

interface ItemTokenInterface {
    function getItemBaseData(
        uint256 itemId
    ) external view returns (address, uint256, uint256);
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
    /**
     * @notice 是否开启ID为0的代币的兑换奖励
     */
    bool public rewardFromMurmes;
    /**
     * @notice 用于标记是否已经提取Murmes提供的奖励
     */
    mapping(bytes32 => bool) isUsedForReward;
    /**
     * @notice 0: Post Task; 1: Submit Item; 2: Audit Item
     */
    uint40[3] public boost;

    constructor(address ms) ERC1155("PlatformToken") {
        Murmes = ms;
        suffix[0] = "Murmes";
        platforms[0] = ms;
        boost[0] = 10;
        boost[1] = 10;
        boost[2] = 5;
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
        require(
            msg.sender == Murmes ||
                MurmesInterface(Murmes).isOperator(msg.sender),
            "PT25"
        );
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

    /**
     * @notice 开启或关闭Murmes奖励
     * @param state 最新的状态
     * Fn 4
     */
    function updateMurmesRewardState(bool state) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "PT45");
        rewardFromMurmes = state;
        emit RewardFromMurmesStateUpdate(state);
    }

    /**
     * @notice 更新不同类型贡献的奖励程度
     * @param flag 贡献类型
     * @param amount 奖励推动值
     */
    function updateMurmesRewardBoost(uint8 flag, uint40 amount) external {
        require(MurmesInterface(Murmes).owner() == msg.sender, "PT55");
        require(flag < 3, "PT51");
        boost[flag] = amount;
        emit RewardFromMurmesBoostUpdate(flag, amount);
    }

    /**
     * @notice 申领Murmes提供的奖励
     * @param ids Task/Item ID集合
     * @param flag 申领类型，0为发布任务，1为提交成品，2为审核成品
     * @return 获得的ID为0的代币数目
     * Fn 6
     */
    function claimRewradFromMurmes(
        uint256[] memory ids,
        uint8 flag
    ) public returns (uint256) {
        require(rewardFromMurmes, "PT65");
        require(flag < 3, "PT61");
        uint256 reward;
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 label = keccak256(abi.encode(flag, ids[i], msg.sender));
            if (!isUsedForReward[label]) {
                if (_checkUserGetRewardAuthority(msg.sender, flag, ids[i])) {
                    reward += boost[flag] * 1e6;
                }
                isUsedForReward[label] = true;
            }
        }
        if (reward > 0) {
            _burn(msg.sender, 0, reward);
        }
        return reward;
    }

    // ***************** Internal Functions *****************
    function _checkUserGetRewardAuthority(
        address user,
        uint8 flag,
        uint256 id
    ) internal view returns (bool) {
        if (flag == 0) {
            return user == MurmesInterface(Murmes).getTaskPublisher(id);
        } else if (flag == 1) {
            address component = MurmesInterface(Murmes).componentGlobal();
            address itemToken = ComponentInterface(component).itemToken();
            (address maker, , ) = ItemTokenInterface(itemToken).getItemBaseData(
                id
            );
            if (maker != user) {
                return false;
            } else {
                DataTypes.ItemStruct memory item = MurmesInterface(Murmes)
                    .getItem(id);
                uint256 lockUpTime = ComponentInterface(component).lockUpTime();
                if (
                    item.state == DataTypes.ItemState.DELETED ||
                    item.stateChangeTime + 2 * lockUpTime >= block.timestamp
                ) {
                    return false;
                } else {
                    return true;
                }
            }
        } else {
            return MurmesInterface(Murmes).isEvaluated(user, id);
        }
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
