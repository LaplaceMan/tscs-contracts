// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;
import {DataTypes} from "./DataTypes.sol";

library Events {
    event PlatformJoin(
        address platform,
        uint256 id,
        string name,
        string symbol,
        uint16 rate1,
        uint16 rate2
    );
    event PlatformSetRate(address platform, uint16 rate1, uint16 rate2);
    event PlatformSetTokenGlobal(address oldToken, address newToken);

    event VideoCreate(
        address platform,
        uint256 realId,
        uint256 id,
        string symbol,
        address creator,
        uint256 initializeView
    );
    event VideoCountsUpdate(address platform, uint256[] id, uint256[] counts);

    event SubtitleCountsUpdate(uint256 taskId, uint256 counts);
    event ApplicationUpdate(
        uint256 taskId,
        uint256 newAmount,
        uint256 newDeadline
    );
    event ApplicationReset(uint256 taskId, uint256 amount);
    event UserWithdraw(
        address user,
        address platform,
        uint256[] day,
        uint256 all
    );
    event VideoPreExtract(uint256 videoId, uint256 unsettled, uint256 surplus);

    event ApplicationSubmit(
        address applicant,
        address platform,
        uint256 videoId,
        uint8 strategy,
        uint256 amount,
        uint32 language,
        uint256 deadline,
        uint256 taskId,
        string src
    );

    event WithdrawPenalty(address to, uint256 amount);

    event WithdrawVideoPlatformFee(
        address to,
        uint256[] ids,
        uint256[] amounts
    );
    event SystemSetFee(uint16 old, uint16 fee);

    event RegisterRepuire(string require, uint256 id);
    event UserJoin(address user, uint256 reputation, int256 deposit);
    event UserLockRewardUpdate(
        address user,
        address platform,
        uint256 day,
        int256 reward
    );
    event UserInfoUpdate(
        address user,
        int256 reputationSpread,
        int256 tokenSpread
    );
    event UserWithdrawDespoit(address user, uint256 amount, uint256 balance);

    event ItemStateChange(
        uint256 itemId,
        DataTypes.ItemState state,
        uint256 taskId
    );

    event ItemGetEvaluation(
        uint256 itemId,
        address evaluator,
        DataTypes.AuditAttitude attitude
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event MutliSigTransferred(address previousMutliSig, address newMutliSig);
}
