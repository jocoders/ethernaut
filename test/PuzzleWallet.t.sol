// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuzzleWallet, PuzzleProxy, Attaker} from "../src/PuzzleWallet.sol";

contract PuzzleWalletTest is Test {
    PuzzleWallet wallet;
    PuzzleProxy proxy;
    Attaker attaker;
    address private ADMIN = makeAddr("Admin");
    uint256 private constant MAX_BALANCE = 1_000_000e18;

    function setUp() public {
        wallet = new PuzzleWallet();

        bytes memory data = abi.encodeWithSignature("init(uint256)", 100e18);
        proxy = new PuzzleProxy(ADMIN, address(wallet), data);
        attaker = new Attaker(address(proxy), address(wallet));

        vm.deal(address(proxy), 10e18);
        vm.deal(address(attaker), 1e18);
    }

    function testAttack() public {
        logAddress();
        address before1 = proxy.admin();
        // console.log('before1', before1);

        attaker.attack();
        address after1 = proxy.admin();
        // console.log('after1', after1);
        // assertEq(after1, address(attaker), 'Admin address is not the attaker');
    }

    function logAddress() public {
        console.log("--------------------------------");
        console.log("wallet", address(wallet));
        console.log("proxy", address(proxy));
        console.log("attaker", address(attaker));
        console.log("ADMIN", ADMIN);
        console.log("THIS", address(this));
        console.log("--------------------------------");
    }
}
