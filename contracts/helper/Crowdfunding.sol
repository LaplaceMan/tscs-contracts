// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../common/token/ERC20/IERC20.sol";
import "../interfaces/IComponentGlobal.sol";
import "../common/token/ERC1155/IERC1155.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

contract Crowdfunding {
    address public Murmes;

    uint256 public numberOfCrowds;

    uint256 constant defaultDelayed = 7 days;

    mapping(uint256 => crowd) crowds;

    mapping(address => mapping(address => uint256)) grants;

    event NewCrowdfunding(
        string source,
        uint256 deadline,
        uint128 target,
        uint128 initial,
        uint256 requireId,
        uint256 end
    );
    event NewDonation(address helpers, uint256 index, uint128 number);
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

    constructor(address ms) {
        Murmes = ms;
    }

    /**
     * @notice 每个众筹申请都会有一个相应的 crowd 结构
     * @param source 源视频链接
     * @param raised 已筹集的代币数量
     * @param target 用于发起申请的目标（字幕制作）费用
     * @param requireId 所需条件
     * @param deadline 申请截至时间
     * @param end 众筹申请的截至时间（未凑齐款项时取消申请）
     * @param taskId 当众筹成功后返回的协议内该申请的 applyId
     * @param frozen 该众筹申请的状态，false 表示仍在进行中
     * @param currency 筹集的代币类型
     */
    struct crowd {
        string source;
        uint128 raised;
        uint128 target;
        uint256 requireId;
        uint256 deadline;
        uint256 end;
        uint256 taskId;
        bool frozen;
        address currency;
        address auditModule;
        address detectionModule;
        address[] helpers;
        uint256[] tokens;
    }

    /**
     * @notice 发出众筹申请
     * @param source 任务必要的源链接
     * @param deadline 众筹成功发出申请后，申请的截至（冻结）日期
     * @param target 用于发起申请的目标（字幕制作）费用
     * @param initial 众筹申请发起者初始时贡献的代币数
     * @param currency 用于众筹的代币类型
     * @param requireId 所需条件的ID
     * @param end 众筹申请的截至时间（未凑齐款项时取消申请）
     * @return 众筹申请 ID
     * Fn 1
     */
    function initiate(
        string memory source,
        uint256 deadline,
        uint128 target,
        uint128 initial,
        address currency,
        uint256 requireId,
        address auditModule,
        address detectionModule,
        uint256 end
    ) external returns (uint256) {
        require(target > 0 && end > block.timestamp, "CF11");
        numberOfCrowds++;
        if (initial > 0) {
            require(
                IERC20(currency).transferFrom(
                    msg.sender,
                    address(this),
                    initial
                ),
                "CF112"
            );
            crowds[numberOfCrowds].raised += initial;
            crowds[numberOfCrowds].helpers.push(msg.sender);
            crowds[numberOfCrowds].tokens.push(initial);
            emit NewDonation(msg.sender, numberOfCrowds, initial);
        }
        crowds[numberOfCrowds].source = source;
        crowds[numberOfCrowds].deadline = deadline;
        crowds[numberOfCrowds].target = target;
        crowds[numberOfCrowds].currency = currency;
        crowds[numberOfCrowds].requireId = requireId;
        crowds[numberOfCrowds].auditModule = auditModule;
        crowds[numberOfCrowds].detectionModule = detectionModule;
        crowds[numberOfCrowds].end = end;

        emit NewCrowdfunding(source, deadline, target, initial, requireId, end);
        return numberOfCrowds;
    }

    /**
     * @notice 参与捐赠
     * @param index 众筹申请的 ID
     * @param amount 捐赠/贡献的代币数目
     * Fn 2
     */
    function donation(uint256 index, uint128 amount) external {
        require(
            !crowds[index].frozen && block.timestamp < crowds[index].end,
            "CF26"
        );
        require(amount > 0, "CF21");
        require(
            IERC20(crowds[index].currency).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "CF212"
        );
        crowds[index].raised += amount;
        crowds[index].helpers.push(msg.sender);
        crowds[index].tokens.push(amount);
        assert(crowds[index].helpers.length == crowds[index].tokens.length);
        emit NewDonation(msg.sender, index, amount);
    }

    /**
     * @notice 当筹集到预期的款项时在Murmes协议中发起申请
     * @param index 众筹申请ID
     * @return 在Murmes协议中发出申请后返回的申请 ID
     * Fn 3
     */
    function success(uint256 index) external returns (uint256) {
        require(
            crowds[index].raised >= crowds[index].target &&
                block.timestamp < crowds[index].end,
            "CF36"
        );
        require(
            IERC20(crowds[index].currency).approve(
                Murmes,
                crowds[index].raised
            ),
            "CF312"
        );
        uint256 taskId = IMurmes(Murmes).postTask(
            DataTypes.PostTaskData({
                platform: Murmes,
                sourceId: 0,
                requireId: crowds[index].requireId,
                source: crowds[index].source,
                settlement: DataTypes.SettlementType.ONETIME,
                amount: crowds[index].raised,
                currency: crowds[index].currency,
                auditModule: crowds[index].auditModule,
                detectionModule: crowds[index].detectionModule,
                deadline: crowds[index].deadline
            })
        );

        crowds[index].taskId = taskId;
        crowds[index].frozen = true;
        for (uint256 i = 0; i < crowds[index].helpers.length; i++) {
            address helpers = crowds[index].helpers[i];
            uint256 amount = crowds[index].tokens[i];
            grants[helpers][crowds[index].currency] += amount;
        }
        emit Success(index, taskId);
        return taskId;
    }

    /**
     * @notice 由于未筹集够金额（超时）而取消申请
     * @param index 众筹申请 ID
     * @param fundId 如果调用者为利益相关者，可提取自己捐赠的额度
     * Fn 4
     */
    function cancel(uint256 index, uint256 fundId) external {
        require(
            block.timestamp > crowds[index].end &&
                crowds[index].raised < crowds[index].target,
            "CF45"
        );
        crowds[index].frozen = true;
        if (crowds[index].helpers[fundId] == msg.sender) {
            require(
                IERC20(crowds[index].currency).transferFrom(
                    address(this),
                    msg.sender,
                    crowds[index].tokens[fundId]
                ),
                "CF412"
            );
            crowds[index].tokens[fundId] = 0;
        }
        emit CancelWithOvertime(index);
    }

    /**
     * @notice 当在Murmes协议发出的申请冻结时，任意一个利益相关者可以决定取消该任务（进行退款）还是恢复任务（取消冻结）。
     * @param index 众筹申请 ID
     * @param fundId 资助顺位
     * @param or 是取消还是恢复
     * @param amount 恢复时额外补充的资金
     * @param times 恢复时延迟时间
     * Fn 5
     */
    function cancel2OrContinue(
        uint256 index,
        uint256 fundId,
        bool or,
        uint128 amount,
        uint128 times
    ) external {
        require(crowds[index].helpers[fundId] == msg.sender, "CF55");
        require(
            crowds[index].frozen == true && crowds[index].taskId != 0,
            "CF51"
        );
        (uint256 items, uint256 adopted, uint256 deadline) = IMurmes(Murmes)
            .getTaskItemsState(crowds[index].taskId);
        require(
            items == 0 && adopted == 0 && block.timestamp > deadline,
            "CF56"
        );
        if (or == true) {
            IMurmes(Murmes).cancelTask(crowds[index].taskId);
            require(
                IERC20(crowds[index].currency).transferFrom(
                    address(this),
                    msg.sender,
                    crowds[index].tokens[fundId]
                ),
                "CF512"
            );
            crowds[index].tokens[fundId] = 0;
            emit CancelWithMurmesOvertime(
                msg.sender,
                index,
                crowds[index].taskId
            );
            crowds[index].taskId = 0;
        } else {
            require(amount > 0, "CF51-2");
            require(
                IERC20(crowds[index].currency).transferFrom(
                    msg.sender,
                    address(this),
                    amount
                ),
                "CF512-2"
            );
            require(
                IERC20(crowds[index].currency).approve(Murmes, amount),
                "CF512-3"
            );
            crowds[index].helpers.push(msg.sender);
            crowds[index].tokens.push(amount);
            emit NewDonation(msg.sender, index, amount);
            IMurmes(Murmes).updateTask(
                crowds[index].taskId,
                amount,
                defaultDelayed * times
            );
            emit ContinueWithMurmesOvertime(
                msg.sender,
                index,
                crowds[index].taskId
            );
        }
    }

    /**
     * @notice 当众筹申请被取消时，提取自己的捐赠额度
     * @param index 众筹申请ID
     * Fn 6
     */
    function exit(uint256 index) external {
        require(crowds[index].frozen && crowds[index].taskId == 0, "CF66");
        uint256 amount;
        for (uint256 i = 0; i < crowds[index].helpers.length; i++) {
            if (crowds[index].helpers[i] == msg.sender) {
                amount += crowds[index].tokens[i];
                crowds[index].tokens[i] = 0;
            }
        }
        if (amount > 0) {
            require(
                IERC20(crowds[index].currency).transferFrom(
                    address(this),
                    msg.sender,
                    amount
                ),
                "CF612"
            );
        }
        emit ExtractAfterCancle(msg.sender, index, amount);
    }

    /**
     * @notice 提取所有成功发起众筹申请后所获得的ID为0的Murmes平台代币
     * @param currency 捐赠的代币类型
     * Fn 7
     */
    function reward(address currency) external {
        require(grants[msg.sender][currency] > 0, "CF75");
        address components = IMurmes(Murmes).componentGlobal();
        address platformToken = IComponentGlobal(components).platformToken();
        uint256 balanceForReward = IERC1155(platformToken).balanceOf(
            address(this),
            0
        );
        uint256 balanceForGrant = IERC20(currency).balanceOf(address(this));
        uint256 amount = (balanceForReward * grants[msg.sender][currency]) /
            balanceForGrant;
        IERC1155(platformToken).safeTransferFrom(
            address(this),
            msg.sender,
            0,
            amount,
            ""
        );
        grants[msg.sender][currency] = 0;
        emit ExtractVT(msg.sender, amount);
    }
}
