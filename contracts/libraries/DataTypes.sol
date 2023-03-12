// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

library DataTypes {
    enum ItemState {
        NORMAL,
        ADOPTED,
        DELETED
    }

    enum AuditAttitude {
        SUPPORT,
        OPPOSE
    }

    enum SettlementType {
        ONETIME,
        DIVIDEND,
        ONETIME_MORTGAGE
    }

    struct ItemStruct {
        DataTypes.ItemState state;
        uint256 taskId;
        address[] supporters;
        address[] opponents;
        uint256 stateChangeTime;
    }

    struct ItemMetadata {
        uint256 taskId;
        string cid;
        uint32 requireId;
        uint256 fingerprint;
    }

    struct UserStruct {
        uint256 reputation;
        uint256 operate;
        address guard;
        int256 deposit;
        mapping(address => mapping(uint256 => uint256)) locks;
    }

    struct TaskStruct {
        address applicant;
        address platform;
        uint256 sourceId;
        uint256 requireId;
        string source;
        DataTypes.SettlementType settlement;
        uint256 amount;
        address currency;
        address auditModule;
        address detectionModule;
        uint256[] items;
        uint256 adopted;
        uint256 deadline;
    }

    struct PostTaskData {
        address platform;
        uint256 sourceId;
        uint256 requireId;
        string source;
        DataTypes.SettlementType settlement;
        uint256 amount;
        address currency;
        address submitModule;
        address auditModule;
        address detectionModule;
        uint256 deadline;
    }

    struct PlatformStruct {
        string name;
        string symbol;
        uint256 platformId;
        uint16 rateCountsToProfit;
        uint16 rateAuditorDivide;
    }

    struct BoxStruct {
        address platform;
        uint256 id;
        address creator;
        uint256 unsettled;
        uint256[] tasks;
    }
}
