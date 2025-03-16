// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

// Nowadays, paying for DeFi operations is impossible, fact.

// A group of friends discovered how to slightly decrease the cost of performing multiple transactions by batching them in one transaction,
// so they developed a smart contract for doing this.

// They needed this contract to be upgradeable in case the code contained a bug,
// and they also wanted to prevent people from outside the group from using it.
// To do so, they voted and assigned two people with special roles in the system:
// The admin, which has the power of updating the logic of the smart contract.
// The owner, which controls the whitelist of addresses allowed to use the contract.
// The contracts were deployed, and the group was whitelisted. Everyone cheered for their accomplishments against evil miners.

// Little did they know, their lunch money was at risk…

//   You'll need to hijack this wallet to become the admin of the proxy.
//   Things that might help:

// Understanding how delegatecall works and how msg.sender and msg.value behaves when performing one.
// Knowing about proxy patterns and the way they handle storage variables.

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
        _delegate(_implementation());
    }

    receive() external payable {
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
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
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

            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}
