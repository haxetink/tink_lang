package ;

import tink.testrunner.*;
import tink.testrunner.Reporter;
import tink.testadapter.*;

import haxe.unit.TestCase;

using tink.CoreApi;

class RunTests {
  static var tests:Array<TestCase> = [
    new TestInit(),
    new ClsTest(),
    new TestFutureDecl(),
    new TestPromiseDecl(),
    new TestSignalDecl(),
    new TestLoops(),
    new TestOptions(),
    new TestPartial(),
    new TestShortLambda(),
    new TestSwitch(),
    #if !php new TestWhen(), #end
    new TestNamedParameters(),
    new TestHxx(),
  ];

  static function main() {
    Runner.run(HaxeUnit.makeBatch(tests), new CompactReporter())
      .handle(Runner.exit);
  }
}
