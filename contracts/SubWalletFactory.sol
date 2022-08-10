// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SubWalletRouter {
    function initialize(address _initOwner) external;
}

contract SubWalletFactory {
    // Events ----------------------------------------------
    event CreateClone(address _newClone, address _owner);

    // Base ------------------------------------------------
    address private _owner;
    modifier onlyOwner {
        require(msg.sender == _owner, "not owner");
        _;
    }
    address private baseContract;

    // External --------------------------------------------
    address uniSwapRouter;
    address aaveEthAllow;
    address aaveGateWay;
    address aaveLendingPool;

    // Internal --------------------------------------------
    mapping(address => address[]) private wallets;

    uint128 private count;
    uint128 private maxWallet;
    uint256 commissionFee; // 50 = 0.5 %

    constructor(address _baseContract, address _uni, address _ethAllow, address _aaveEth, address _aavePool, address[] memory _dWhite, address[] memory _sWhite, uint128 _maxSupply) {
        // ------------------------------
        _owner = msg.sender;
        baseContract = _baseContract;
        // ------------------------------
        uniSwapRouter = _uni;
        aaveEthAllow = _ethAllow;
        aaveGateWay = _aaveEth;
        aaveLendingPool = _aavePool;
        // ------------------------------
        count = 0;
        maxWallet = _maxSupply;
        commissionFee = 50;
        // ------------------------------
    }

    // Func ------------------------------------------------
    function createWallet() external {
        require((count + 1) <= maxWallet, "Max Wallet");
        address identicalChild = _clone(baseContract);
        count = count + 1;
        wallets[msg.sender].push(identicalChild);
        SubWalletRouter(identicalChild).initialize(msg.sender);
        emit CreateClone(identicalChild, msg.sender);
    }

    function _clone(address _baseContract) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _baseContract))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    // Owner -----------------------------------------------
    function setOwner(address _newAdd) external onlyOwner {
        _owner = _newAdd;
    }

    function setBase(address _newAdd) external onlyOwner {
        baseContract = _newAdd;
    }

    function setUni(address _newAdd) external onlyOwner {
        uniSwapRouter = _newAdd;
    }

    function setAaveEthAllow(address _newAdd) external onlyOwner {
        aaveEthAllow = _newAdd;
    }

    function setAaveEth(address _newAdd) external onlyOwner {
        aaveGateWay = _newAdd;
    }

    function setAavePool(address _newAdd) external onlyOwner {
        aaveLendingPool = _newAdd;
    }

    function setMaxWallet(uint128 _max) external onlyOwner {
        maxWallet = _max;
    }

    function setCommissionFee(uint256 _fee) external onlyOwner {
        commissionFee = _fee;
    }

    // View ------------------------------------------------
    function totalCreated() external view returns (uint128) {
        return count;
    }

    function getMaxWallet() external view returns (uint128) {
        return maxWallet;
    }

    function getWallets(address _user) external view returns (address[] memory) {
        return wallets[_user];
    }

    function getUni() external view returns (address) {
        return uniSwapRouter;
    }

    function getAaveAllow() external view returns (address) {
        return aaveEthAllow;
    }

    function getAaveEth() external view returns (address) {
        return aaveGateWay;
    }

    function getAavePool() external view returns (address) {
        return aaveLendingPool;
    }

    function getCommissionFee() external view returns (uint) {
        return commissionFee;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}