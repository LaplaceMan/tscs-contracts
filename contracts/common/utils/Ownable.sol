/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-12-05 20:23:26
 * @Description: 权限控制合约
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    mapping(address => bool) opeators;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OpeatorsStateChange(address[] indexed opeators, bool indexed state);

    modifier onlyOwner() {
        require(msg.sender == _owner, "ER5");
        _;
    }

    modifier auth() {
        require(opeators[msg.sender] == true, "ER5");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "ER1");
        _setOwner(newOwner);
    }

    function setOperators(address[] memory operators, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < operators.length; i++) {
            opeators[operators[i]] = state;
        }
        emit OpeatorsStateChange(operators, state);
    }

    function isOperator(address operator) public view returns (bool) {
        return opeators[operator];
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
