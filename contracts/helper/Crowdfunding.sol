// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IMurmes.sol";
import "../common/token/ERC20/IERC20.sol";
import "../interfaces/IComponentGlobal.sol";
import "../common/token/ERC1155/IERC1155.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

contract Crowdfunding {
    /**
     * @notice Murmes主合约地址
     */
    address public Murmes;
    /**
     * @notice 众筹申请总数
     */
    uint256 public totalCrowds;
    /**
     * @notice 更新已经在Murmes成功提交的众包任务的有效时间时，默认的延迟时间
     */
    uint256 constant defaultDelayed = 7 days;
    /**
     * @notice 记录众筹申请的详细信息
     */
    mapping(uint256 => crowd) crowds;
    /**
     * @notice 用户参与捐赠的不同代币的数目
     */
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

    struct crowd {
        string source; // 源视频链接
        uint128 raised; // 已筹集的代币数量
        uint128 target; // 用于发起申请的目标费用
        uint256 requireId; // 所需条件
        uint256 deadline; // 申请截至时间
        uint256 end; // 众筹申请的截至时间（未凑齐款项时取消申请）
        uint256 taskId; // 当众筹成功后返回的Murmes内该申请的 applyId
        bool frozen; // 该众筹申请的状态，false 表示仍在进行中
        address currency; // 筹集的代币类型
        address auditModule; // 众包任务所采用的审核（Item状态改变）模块
        address detectionModule; // 众包任务所采用的Item检测模块
        address[] helpers; // 参与众筹的用户
        uint256[] tokens; // 用户捐赠的代币数目
    }

    /**
     * @notice 发出众筹申请
     * @param source 任务必要的源链接
     * @param deadline 众筹成功发出申请后，申请的截至（冻结）日期
     * @param target 用于发起申请的目标费用
     * @param initial 众筹申请发起者初始时贡献的代币数
     * @param currency 用于众筹的代币类型
     * @param requireId 所需条件的ID
     * @param auditModule 众包任务所采用的审核（Item状态改变）模块合约地址
     * @param detectionModule 众包任务所采用的Item检测模块合约地址
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
        totalCrowds++;
        if (initial > 0) {
            require(
                IERC20(currency).transferFrom(
                    msg.sender,
                    address(this),
                    initial
                ),
                "CF112"
            );
            crowds[totalCrowds].raised += initial;
            crowds[totalCrowds].helpers.push(msg.sender);
            crowds[totalCrowds].tokens.push(initial);
            emit NewDonation(msg.sender, totalCrowds, initial);
        }
        crowds[totalCrowds].source = source;
        crowds[totalCrowds].deadline = deadline;
        crowds[totalCrowds].target = target;
        crowds[totalCrowds].currency = currency;
        crowds[totalCrowds].requireId = requireId;
        crowds[totalCrowds].auditModule = auditModule;
        crowds[totalCrowds].detectionModule = detectionModule;
        crowds[totalCrowds].end = end;

        emit NewCrowdfunding(source, deadline, target, initial, requireId, end);
        return totalCrowds;
    }

    /**
     * @notice 参与捐赠
     * @param index 众筹申请的ID
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
     * @return 在Murmes协议中发出申请后返回的申请ID
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
     * @param index 众筹申请ID
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
     * @param index 众筹申请ID
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
