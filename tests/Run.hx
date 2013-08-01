package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class Run implements tink.lang.Sugar {
	static var tests:Array<TestCase> = [
		new TestInit(),
		new ClsTest(),
		new TestFutureDecl(),
		new TestSignalDecl(),
	];
	static function main() {
		var runner = new TestRunner();
		for (test in tests)
			runner.add(test);
		runner.run();
	}
}