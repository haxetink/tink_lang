package ;

import haxe.ds.StringMap;
import tink.Lang;
using Lambda;

private class Dummy implements tink.Lang {
	public function new() {}
	public function test(o1 = [var x = 5, var y = 'bar'], o2 = [var a = o1.x, var b = 7]) {		
		return { o1: o1, o2: o2 };
	}
}

class TestOptions extends Base {
	function test() {
		var d = new Dummy();
		for (i in 0...10) {
			var r = d.test({x:4});
			
			assertEquals(r.o1.x, r.o2.a);
		}
		
	}
}