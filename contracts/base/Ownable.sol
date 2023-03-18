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

    /**
     * @notice 转移Owner权限
     * @param newOwner 新的Owner地址
     * Fn 3
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "O31");
        _setOwner(newOwner);
    }

    /**
     * @notice 转移多签权限
     * @param newMutliSig 新的多签地址
     * @ Fn 4
     */
    function transferMutliSig(address newMutliSig) external {
        require(msg.sender == _multiSig || msg.sender == _owner, "O45");
        require(newMutliSig != address(0), "O41");
        _setMutliSig(newMutliSig);
    }

    /**
     * @notice 设置/替换拥有特殊权限的操作员（合约）地址
     * @param old 旧的操作员地址，被撤销
     * @param replace 新的操作员权限，被授予
     */
    function setOperatorByTool(address old, address replace) public {
        require(opeators[msg.sender] == true, "O55");
        if (old == address(0)) {
            opeators[replace] = true;
        } else {
            opeators[old] = false;
            opeators[replace] = true;
        }
    }

    // ***************** Internal Functions *****************
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    function _setMutliSig(address newMutliSig) internal {
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
