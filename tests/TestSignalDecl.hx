package ;

import tink.lang.Sugar;

class TestSignalDecl extends Base implements Sugar {
	@:signal var foo:Int;
	@:signal var bar = this.foo.map([i] => 2 * i);
	function test() {
		var r = [];
		
		function compare(expected:Array<Int>)
			for ([expected in expected, result in r])
				assertEquals(expected, result);
			
		foo.when(r.push);
		bar.when(r.push);
		
		_foo.invoke(4);
		compare([8, 4]);
		_foo.invoke(5);
		compare([8, 4, 10, 5]);
	}
}