package ;

import tink.Lang;

class TestLoops extends Base implements Lang {
	function testArray() {
		var a = [for (i in 0...100) Std.string(i)];
		var l = Lambda.list(a),
			sm = [for (x in a) x => x],
			im = [for (x in a) Std.parseInt(x) => x];
		inline function sort<T>(a:Array<T>) {
			var ret = a.join(',').split(',');
			ret.sort(Reflect.compare);
			return ret.join(',');			
		}			

		assertEquals(sort(a), sort([for ([i in sm.keys()]) i]));
		assertEquals(sort(a), sort([for ([i in im.keys()]) i]));
		
		assertEquals(sort(a), sort([for ([i in sm]) i]));
		assertEquals(sort(a), sort([for ([i in im]) i]));
		
		for ([x in a, i in 0...a.length])
			assertEquals(Std.string(i), x);
		
		for ([x in l, i in 0...l.length])
			assertEquals(Std.string(i), x);
	}
}