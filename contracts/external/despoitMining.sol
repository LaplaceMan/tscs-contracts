/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-12-30 15:38:40
 * @Description: 质押 Zimu 代币获得收益，平台分别收取 (Zimu) 25% 和 (VT) 33%
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../components/Vault.sol";
import "../interfaces/IPlatform.sol";
import "../common/utils/ReentrancyGuard.sol";

contract DepositMining is Vault, ReentrancyGuard {
    // 参与质押的总份额
    uint256 public points;
    // 最小质押时间
    uint256 constant min = 30 days;
    // 平台收费地址
    address public feeTo;
    // 每个质押者都有相应的 deposit 结构
    mapping(address => deposit) deposits;
    // 字幕的解锁期
    mapping(uint256 => uint256) cooling;

    /**
     * @notice 记录用户的质押信息
     * @param subtitleId “质押” 的字幕 ID
     * @param start 质押开始时间
     * @param tokens 质押的 Zimu 代币数量
     * @param duration 选择质押的时间
     */
    struct deposit {
        uint256 subtitleId;
        uint256 start;
        uint256 parts;
        uint128 tokens;
        uint128 duration;
    }

    event NewDepositMining(
        address user,
        uint128 allTokens,
        uint256 allParts,
        uint256 subtitleId,
        uint256 unlockTime
    );

    event NewWithdrawProfit(address user, uint256 zimu, uint256 vt);

    constructor(address ms, address to) Vault(ms) {
        feeTo = to;
    }

    // 开平方根
    // label DM1
    function _sqrt(uint256 x) public pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /**
     * @notice 加入质押
     * @param subtitleId 质押字幕 ID (被确认且经过一定的时间)
     * @param number 要质押的 Zimu 代币数量
     * @param duration 要质押的时间
     * @return 所占的份额
         // label DM2
     */
    function join(
        uint256 subtitleId,
        uint128 number,
        uint128 duration
    ) public returns (uint256) {
        // 质押代币数量应当大于 0
        require(number > 0, "DM2-1");
        // 质押时间应当大于平台设置的最小质押时间
        require(duration > min, "DM2-1-2");
        // 质押的字幕 ST 没有处于冷却期
        require(block.timestamp > cooling[subtitleId], "DM2-1-3");
        // 手续费已经开启
        require(IMurmes(Murmes).fee() > 0, "DM2-5");
        (uint8 state, , uint256 change, , ) = IMurmes(Murmes)
            .getSubtitleBaseInfo(subtitleId);
        // 质押的字幕 ST 是合法的，即被确认且经过了一定的时间（审核期）
        uint256 lockUpTime = IMurmes(Murmes).lockUpTime();
        require(state == 1 && block.timestamp > change + lockUpTime, "DM2-1-3");
        address zimu = IMurmes(Murmes).zimuToken();
        require(
            IZimu(zimu).transferFrom(msg.sender, address(this), number),
            "DM2-12"
        );
        cooling[subtitleId] = block.timestamp + 2 * duration;
        uint256 add = _sqrt(number * duration);
        if (deposits[msg.sender].tokens != 0) {
            // 如果用户已质押，再次调用此功能认为是重新质押，但会累计以往已质押的代币
            add += _sqrt(deposits[msg.sender].tokens * duration);
            number += deposits[msg.sender].tokens;
        }
        deposits[msg.sender] = deposit(
            subtitleId,
            deposits[msg.sender].start,
            add,
            number,
            deposits[msg.sender].duration + duration
        );
        points += add;
        emit NewDepositMining(
            msg.sender,
            number,
            add,
            subtitleId,
            block.timestamp + duration
        );
        return add;
    }

    /**
     * @notice 取出质押的代币和奖励
     * @return 总计的额外 Zimu 代币和 VT 代币收入
     * label DM3
     */
    function exit() public nonReentrant returns (uint256, uint256) {
        require(
            block.timestamp >
                deposits[msg.sender].start + deposits[msg.sender].duration,
            "DM3-5"
        );
        address zimu = IMurmes(Murmes).zimuToken();
        uint256 fee0 = (feeIncome[0] * deposits[msg.sender].parts) / points;
        require(
            IZimu(zimu).transferFrom(
                address(this),
                msg.sender,
                deposits[msg.sender].tokens + (fee0 - fee0 / 4)
            ),
            "DM3-12"
        );
        require(
            IZimu(zimu).transferFrom(address(this), feeTo, fee0 / 4),
            "DM3-12-2"
        );
        feeIncome[0] -= fee0;

        address platform = IMurmes(Murmes).platforms();
        uint256 all = IPlatform(platform).totalPlatforms();
        uint256 tokens;
        if (all > 1) {
            uint256[] memory ids = new uint256[](all - 1);
            uint256[] memory amounts = new uint256[](all - 1);
            uint256[] memory fees = new uint256[](all - 1);
            for (uint256 i = 1; i < all; i++) {
                ids[i - 1] = i;

                uint256 get = (feeIncome[i] * deposits[msg.sender].parts) /
                    points;
                amounts[i - 1] = get - get / 3;
                fees[i - 1] = get / 3;
                feeIncome[i] -= get;
                tokens += get;
            }
            if (tokens > 0) {
                address vt = IMurmes(Murmes).videoToken();
                IVT(vt).safeBatchTransferFrom(
                    address(this),
                    msg.sender,
                    ids,
                    amounts,
                    ""
                );
                IVT(vt).safeBatchTransferFrom(
                    address(this),
                    feeTo,
                    ids,
                    fees,
                    ""
                );
            }
        }
        delete deposits[msg.sender];
        emit NewWithdrawProfit(msg.sender, fee0, tokens);
        return (fee0, tokens);
    }

    /**
     * @notice 设置新的费用接收地址
     * @param newFeeTo 新的费用接收地址
     * label DM4
     */
    function setFeeTo(address newFeeTo) external {
        require(IMurmes(Murmes).multiSig() == msg.sender, "DM4-5");
        feeTo = newFeeTo;
    }
}
