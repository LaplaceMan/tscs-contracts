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

    address private _multiSig;

    mapping(address => bool) opeators;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event MutliSigTransferred(address previousMutliSig, address newMutliSig);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Own-ER5");
        _;
    }

    modifier auth() {
        require(opeators[msg.sender] == true, "Own-ER5");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function multiSig() public view returns (address) {
        return _multiSig;
    }

    function isOperator(address operator) public view returns (bool) {
        return opeators[operator];
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Own-ER1");
        _setOwner(newOwner);
    }

    function transferMutliSig(address newMutliSig) external {
        require(msg.sender == _multiSig, "Own-ER5");
        _multiSig = newMutliSig;
    }

    function _replaceOperator(address old, address replace) internal {
        opeators[old] = false;
        opeators[replace] = true;
    }

    function _setOperator(address newOperator) internal {
        opeators[newOperator] = true;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setMutliSig(address newMutliSig) internal {
        address oldMutliSig = _multiSig;
        _multiSig = newMutliSig;
        emit MutliSigTransferred(oldMutliSig, newMutliSig);
    }
}
