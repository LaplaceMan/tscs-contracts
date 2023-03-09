/**
 * @Author: LaplaceMan 505876833@qq.com
 * @Date: 2022-12-05 20:23:26
 * @Description: 权限控制合约
 * @Copyright (c) 2022 by LaplaceMan email: 505876833@qq.com, All Rights Reserved.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    /**
     * @notice 管理员，一般为DAO
     */
    address private _owner;
    /**
     * @notice 多签地址，受DAO管理
     */
    address private _multiSig;
    /**
     * @notice 相应的区块链地址是否拥有特殊权限
     */
    mapping(address => bool) opeators;

    // Fn 1
    modifier onlyOwner() {
        require(msg.sender == _owner, "O15");
        _;
    }
    // Fn 2
    modifier auth() {
        require(opeators[msg.sender] == true, "O25");
        _;
    }

    // Fn 3
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "O31");
        _setOwner(newOwner);
    }

    // Fn 4
    function transferMutliSig(address newMutliSig) external {
        require(msg.sender == _multiSig || msg.sender == _owner, "O45");
        require(newMutliSig != address(0), "O41");
        _multiSig = newMutliSig;
    }

    // Fn 5
    function setOperatorByTool(address old, address replace) internal {
        require(opeators[msg.sender] == true, "O55");
        if (old == address(0)) {
            opeators[replace] = true;
        } else {
            opeators[old] = false;
            opeators[replace] = true;
        }
    }

    // Fn 6
    function _setOwner(address newOwner) internal {
        // address oldOwner = _owner;
        _owner = newOwner;
    }

    // Fn 7
    function _setMutliSig(address newMutliSig) internal {
        // address oldMutliSig = _multiSig;
        _multiSig = newMutliSig;
    }

    // ***************** View Functions *****************
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function multiSig() public view returns (address) {
        return _multiSig;
    }

    function isOperator(address operator) public view returns (bool) {
        return opeators[operator];
    }
}
