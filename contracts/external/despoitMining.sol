/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-12-30 15:38:40
 * @Description: 质押 Zimu 代币获得收益，平台分别收取 (Zimu) 50% 和 (VT) 25%
 * @Copyright (c) 2022 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../components/Vault.sol";
import "../interfaces/IZimu.sol";
import "../interfaces/IMurmes.sol";
import "../interfaces/IPlatform.sol";

contract DepositMining is Vault {
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

    constructor(address ss, address to) Vault(ss) {
        feeTo = to;
    }

    // 开平方根
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
     */
    function join(
        uint256 subtitleId,
        uint128 number,
        uint128 duration
    ) public returns (uint256) {
        // 质押代币数量应当大于 0
        require(number > 0, "ER1");
        // 质押时间应当大于平台设置的最小质押时间
        require(duration > min, "ER1");
        // 质押的字幕 ST 没有处于冷却期
        require(block.timestamp > cooling[subtitleId], "ER1");
        (uint8 state, , uint256 change, , ) = IMurmes(Murmes)
            .getSubtitleBaseInfo(subtitleId);
        // 质押的字幕 ST 是合法的，即被确认且经过了一定的时间（审核期）
        require(state == 1 && block.timestamp > change + 14 days, "ER1");
        address zimu = IMurmes(Murmes).zimuToken();
        IZimu(zimu).transferFrom(msg.sender, address(this), number);
        cooling[subtitleId] = block.timestamp + 2 * duration;
        uint256 add = _sqrt(number * duration);
        if (deposits[msg.sender].tokens != 0) {
            // 如果用户已质押，再次调用此功能认为是重新质押，但会累计以往已质押的代币
            add += _sqrt(deposits[msg.sender].tokens * duration);
            number += deposits[msg.sender].tokens;
        }
        deposits[msg.sender] = deposit(
            subtitleId,
            block.timestamp,
            add,
            number,
            duration
        );
        points += add;
        return add;
    }

    /**
     * @notice 取出质押的代币和奖励
     * @return 总计的额外 Zimu 代币和 VT 代币收入
     */
    function exit() public returns (uint256, uint256) {
        require(
            block.timestamp >
                deposits[msg.sender].start + deposits[msg.sender].duration,
            "ER5"
        );
        address zimu = IMurmes(Murmes).zimuToken();
        uint256 fee0 = (feeIncome[0] * deposits[msg.sender].parts) / points;
        IZimu(zimu).transferFrom(
            address(this),
            msg.sender,
            deposits[msg.sender].tokens + fee0 / 2
        );
        IZimu(zimu).transferFrom(address(this), feeTo, fee0 - fee0 / 2);
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
                amounts[i - 1] = get - get / 4;
                fees[i - 1] = get / 4;
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
        return (fee0, tokens);
    }
}
