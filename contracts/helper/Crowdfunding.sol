/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2023-01-24 13:26:23
 * @Description: 该合约可以帮助申请们共同出资为某一个视频申请特定语言的字幕，但是支付策略只能为一次性支付，即需要捐赠的是Zimu代币
 * @Copyright (c) 2023 by LaplaceMan 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../interfaces/IZimu.sol";
import "../interfaces/IVT.sol";

contract Crowdfunding {
    /**
     * @notice 总的众筹申请个数
     */
    uint256 public all;
    /**
     * @notice 协议主合约地址
     */
    address immutable Murmes;
    /**
     * @notice 总贡献的Zimu代币数
     */
    uint256 public cumulative;
    /**
     * @notice 当延迟申请的持续时间时，默认延时为30天
     */
    uint256 constant defaultDelayed = 30 days;
    /**
     * @notice 众筹申请号和 crowd 结构的映射
     */
    mapping(uint256 => crowd) public crowds;
    /**
     * @notice 用户贡献过的字幕代币数，用于计算待提取 ID 为 0 的 VT 的份额
     */
    mapping(address => uint256) public contribution;
    /**
     * @notice 用户是否参与过某个众筹
     */
    mapping(address => mapping(uint256 => bool)) participated;

    constructor(address ms) {
        Murmes = ms;
    }

    event NewCrowdfunding(
        string source,
        uint256 deadline,
        uint112 target,
        uint112 initial,
        uint32 language,
        uint256 end
    );
    event NewDonation(address helper, uint256 index, uint112 number);
    event Success(uint256 index, uint256 indexInMurmes);
    event CancelWithOvertime(uint256 index);
    event CancelWithMurmesOvertime(
        address caller,
        uint256 index,
        uint256 indexInMurmes
    );
    event ContinueWithMurmesOvertime(
        address caller,
        uint256 index,
        uint256 indexInMurmes
    );
    event ExtractAfterCancle(address caller, uint256 index, uint256 number);
    event ExtractVT(address caller, uint256 numebr);
    /**
     * @notice 每个众筹申请都会有一个相应的 crowd 结构
     * @param source 源视频链接
     * @param raised 已筹集的代币数量
     * @param target 用于发起申请的目标（字幕制作）费用
     * @param language 所需字幕的语言
     * @param deadline 申请截至时间
     * @param end 众筹申请的截至时间（未凑齐款项时取消申请）
     * @param applyId 当众筹成功后返回的协议内该申请的 applyId
     * @param frozen 该众筹申请的状态，false 表示仍在进行中
     * @param helper 参与众筹的用户地址
     * @param token 参与众筹的用户所贡献的代币数目
     */
    struct crowd {
        string source;
        uint112 raised;
        uint112 target;
        uint32 language;
        uint256 deadline;
        uint256 end;
        uint256 applyId;
        bool frozen;
        address[] helper;
        uint112[] token;
    }

    /**
     * @notice 发出众筹申请
     * @param source 视频源链接
     * @param deadline 众筹成功发出申请后，申请的截至（冻结）日期
     * @param target 用于发起申请的目标（字幕制作）费用
     * @param initial 众筹申请发起者初始时贡献的代币数
     * @param language 所需字幕的语言 ID
     * @param end 众筹申请的截至时间（未凑齐款项时取消申请）
     * @return 众筹申请 ID
     * label CF1
     */
    function initiate(
        string memory source,
        uint256 deadline,
        uint112 target,
        uint112 initial,
        uint32 language,
        uint256 end
    ) external returns (uint256) {
        require(target > 0 && end > block.timestamp, "CF1-1");
        all++;
        if (initial > 0) {
            address zimu = IMurmes(Murmes).zimuToken();
            require(
                IZimu(zimu).transferFrom(msg.sender, address(this), initial),
                "CF1-12"
            );
            crowds[all].raised += initial;
            crowds[all].helper.push(msg.sender);
            crowds[all].token.push(initial);
            emit NewDonation(msg.sender, all, initial);
        }
        crowds[all].source = source;
        crowds[all].deadline = deadline;
        crowds[all].target = target;
        crowds[all].language = language;
        crowds[all].end = end;
        participated[msg.sender][all] = true;
        emit NewCrowdfunding(source, deadline, target, initial, language, end);
        return all;
    }

    /**
     * @notice 参与捐赠
     * @param index 众筹申请的 ID
     * @param number 捐赠/贡献的代币数目
     * label CF2
     */
    function donation(uint256 index, uint112 number)
        external
        returns (uint256)
    {
        require(
            !crowds[index].frozen &&
                crowds[index].target > 0 &&
                block.timestamp < crowds[index].end,
            "CF2-5"
        );
        require(number > 0, "CF2-1");
        address zimu = IMurmes(Murmes).zimuToken();
        require(
            IZimu(zimu).transferFrom(msg.sender, address(this), number),
            "CF2-12"
        );
        crowds[index].helper.push(msg.sender);
        crowds[index].token.push(number);
        assert(crowds[index].helper.length == crowds[index].token.length);
        crowds[index].raised += number;
        participated[msg.sender][index] = true;
        emit NewDonation(msg.sender, index, number);
        return crowds[index].helper.length - 1;
    }

    /**
     * @notice 当筹集到预期的款项时在 Murmes 协议中发起申请
     * @param index 众筹申请 ID
     * @return 在 Murmes 协议中发出申请后返回的申请 ID
     * label CF3
     */
    function success(uint256 index) external returns (uint256) {
        require(
            crowds[index].raised >= crowds[index].target &&
                block.timestamp < crowds[index].end,
            "CF3-5"
        );
        address zimu = IMurmes(Murmes).zimuToken();
        require(IZimu(zimu).approve(Murmes, crowds[index].raised), "CF3-12");
        uint256 id = IMurmes(Murmes).submitApplication(
            Murmes,
            0,
            0,
            crowds[index].raised,
            crowds[index].language,
            crowds[index].deadline,
            crowds[index].source
        );
        crowds[index].applyId = id;
        crowds[index].frozen = true;
        for (uint256 i = 0; i < crowds[index].helper.length; i++) {
            address helper = crowds[index].helper[i];
            uint256 amount = crowds[index].token[i];
            contribution[helper] += amount;
            cumulative += amount;
        }
        emit Success(index, id);
        return id;
    }

    /**
     * @notice 由于未筹集够金额（超时）而取消申请
     * @param index 众筹申请 ID
     * @param refund 如果调用者为利益相关者，可提取自己捐赠的额度
     * label CF4
     */
    function cancel(uint256 index, uint256 refund) external {
        require(
            block.timestamp > crowds[index].end &&
                crowds[index].frozen == false,
            "CF4-5"
        );
        crowds[index].frozen = true;
        if (crowds[index].helper[refund] == msg.sender) {
            address zimu = IMurmes(Murmes).zimuToken();
            require(
                IZimu(zimu).transferFrom(
                    address(this),
                    msg.sender,
                    crowds[index].token[refund]
                ),
                "CF4-12"
            );
            crowds[index].token[refund] = 0;
        }
        emit CancelWithOvertime(index);
    }

    /**
     * @notice 当在 Murmes 协议发出的申请冻结时，任意一个利益相关者可以决定取消该申请（进行退款）还是恢复申请（取消冻结）。
     * @param index 众筹申请 ID
     * @param or 是取消还是恢复
     * @param number 若取消时是利益相关者的捐赠顺位，恢复时是额外补充的资金
     * label CF5
     */
    function cancel2OrContinue(
        uint256 index,
        bool or,
        uint112 number
    ) external {
        require(participated[msg.sender][index] = true, "CF5-5");
        require(
            crowds[index].frozen == true && crowds[index].applyId != 0,
            "CF5-5-2"
        );
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256[] memory subtitles,
            uint256 adopted,
            uint256 deadline
        ) = IMurmes(Murmes).tasks(crowds[index].applyId);
        require(
            subtitles.length == 0 && adopted == 0 && block.timestamp > deadline,
            "CF5-5-3"
        );
        if (or == true) {
            IMurmes(Murmes).cancel(crowds[index].applyId);
            if (crowds[index].helper[number] == msg.sender) {
                address zimu = IMurmes(Murmes).zimuToken();
                require(
                    IZimu(zimu).transferFrom(
                        address(this),
                        msg.sender,
                        crowds[index].token[number]
                    ),
                    "CF5-12"
                );
                crowds[index].token[number] = 0;
                emit CancelWithMurmesOvertime(
                    msg.sender,
                    index,
                    crowds[index].applyId
                );
            }
            crowds[index].applyId = 0;
        } else {
            if (number > 0) {
                address zimu = IMurmes(Murmes).zimuToken();
                require(
                    IZimu(zimu).transferFrom(msg.sender, address(this), number),
                    "CF5-12-2"
                );
                require(IZimu(zimu).approve(Murmes, number), "CF5-12-3");
                crowds[index].helper.push(msg.sender);
                crowds[index].token.push(number);
                emit NewDonation(msg.sender, index, number);
            }
            IMurmes(Murmes).updateApplication(
                crowds[index].applyId,
                number,
                defaultDelayed
            );
            emit ContinueWithMurmesOvertime(
                msg.sender,
                index,
                crowds[index].applyId
            );
        }
    }

    /**
     * @notice 当众筹申请被取消时，提取自己的捐赠额度
     * @param index 众筹申请 ID
     * @param refund 在捐赠者中的索引
     * label CF6
     */
    function exit(uint256 index, uint256[] memory refund) external {
        require(crowds[index].frozen && crowds[index].applyId == 0, "CF6-1");
        address zimu = IMurmes(Murmes).zimuToken();
        uint256 amount;
        for (uint256 i = 0; i < refund.length; i++) {
            require(crowds[index].helper[refund[i]] == msg.sender, "CF6-5");
            amount += crowds[index].token[refund[i]];
            crowds[index].token[refund[i]] = 0;
        }
        if (amount > 0) {
            require(
                IZimu(zimu).transferFrom(address(this), msg.sender, amount),
                "CF6-12"
            );
        }
        emit ExtractAfterCancle(msg.sender, index, amount);
    }

    /**
     * @notice 提取所有成功发起众筹申请后所获得的 ID 为 0 的代币
     * label CF7
     */
    function reward() external {
        require(contribution[msg.sender] > 0, "CF7-5");
        address vt = IMurmes(Murmes).videoToken();
        uint256 balance = IVT(vt).balanceOf(address(this), 0);
        uint256 amount = (balance * contribution[msg.sender]) / cumulative;
        IVT(vt).safeTransferFrom(address(this), msg.sender, 0, amount, "");
        delete contribution[msg.sender];
        emit ExtractVT(msg.sender, amount);
    }
}
