package ;

import tink.testrunner.*;
import tink.testadapter.*;

import haxe.unit.*;

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
    #if tink_testadapter
      Runner.run(HaxeUnit.makeBatch(tests), new Reporter.CompactReporter())
        .handle(Runner.exit);
    #else
    var runner = new TestRunner();
    for (t in tests)
      runner.add(t);

    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    );
    #end
  }
}
