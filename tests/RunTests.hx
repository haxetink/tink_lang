package ;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

using tink.CoreApi;

class RunTests {
	static var tests:Array<TestCase> = [
		new TestInit(),
		new ClsTest(),
		new TestFutureDecl(),
		new TestSignalDecl(),
		new TestLoops(),
		new TestOptions(),
		new TestPartial(),
		new TestShortLambda(),
		new TestSwitch(),
		new TestWhen(),
	];
	
	static function main() {
		#if js //works for nodejs and browsers alike
		var buf = [];
		TestRunner.print = function (s:String) {
			var parts = s.split('\n');
			if (parts.length > 1) {
				parts[0] = buf.join('') + parts[0];
				buf = [];
				while (parts.length > 1)
					untyped console.log(parts.shift());
			}
			buf.push(parts[0]);
		}
		#end
		var runner = new TestRunner();
		for (test in tests)
			runner.add(test);
		runner.run();

	}
}
