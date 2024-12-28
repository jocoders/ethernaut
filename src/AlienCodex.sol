// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// You've uncovered an Alien contract. Claim ownership to complete the level.

// Things that might help

// Understanding how array storage works
// Understanding ABI specifications
// Using a very underhanded approach

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.pop();
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }

    // ------------------------------------------------------------------------------------------------

    function getSlots() public pure returns (uint256 slotOwner, uint256 slotContact, uint256 slotCodex) {
        assembly {
            slotOwner := owner.slot
            slotContact := contact.slot
            slotCodex := codex.slot
        }
    }

    function getOwnerData() public view returns (address ownerData) {
        assembly {
            let slotOwner := owner.slot
            ownerData := sload(slotOwner)
        }
    }

    function getContactData() public view returns (bool contactData) {
        assembly {
            let slotContact := contact.slot
            contactData := sload(slotContact)
        }
    }
}
