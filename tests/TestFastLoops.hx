package ;

import tink.Lang;

class TestFastLoops extends Base implements Lang {
	function testArray() {
		var a = [for (i in 0...100) Std.string(i)],
			count = 5000;
		#if java
			count *= 3;
		#elseif cpp
			count *= 10;
		#end
		var l = Lambda.list(a),
			sm = [for (x in a) x => x],
			im = [for (x in a) Std.parseInt(x) => x];
		
		#if benchmark
		@measure('tink Array' * (count * 20)) Tink.array(a);
		@measure('haxe Array' * (count * 20)) Haxe.array(a);
		
		@measure('tink List' * (count * 20)) Tink.list(l);
		@measure('haxe List' * (count * 20)) Haxe.list(l);
		
		@measure('tink StringMap' * count) Tink.smap(sm);
		@measure('haxe StringMap' * count) Haxe.smap(sm);
		
		@measure('tink StringMap keys' * count) Tink.smapk(sm);
		@measure('haxe StringMap keys' * count) Haxe.smapk(sm);
		
		@measure('tink IntMap' * count) Tink.imap(im);
		@measure('haxe IntMap' * count) Haxe.imap(im);
		
		@measure('tink IntMap keys' * count) Tink.imapk(im);
		@measure('haxe IntMap keys' * count) Haxe.imapk(im);
		#end
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

class Tink implements Lang {		
	static public inline function array<A>(a:Array<A>)
		for ([x in a]) {}
		
	static public inline function list<A>(l:List<A>)
		for ([x in l]) {}
		
	static public inline function smap<A>(m:Map<String, A>)
		for ([x in m]) {}
		
	static public inline function smapk<A>(m:Map<String, A>)
		for ([x in m.keys()]) {}
		
	static public inline function imap<A>(m:Map<Int, A>)
		for ([x in m]) {}
		
	static public inline function imapk<A>(m:Map<Int, A>)
		for ([x in m.keys()]) {}
}

class Haxe {
	static public inline function array<A>(a:Array<A>) 
		for (x in a) {}
		
	static public inline function list<A>(l:List<A>)
		for (x in l) {}
		
	static public inline function smap<A>(m:Map<String, A>)
		for (x in m) {}
		
	static public inline function smapk<A>(m:Map<String, A>)
		for (x in m.keys()) {}
		
	static public inline function imap<A>(m:Map<Int, A>)
		for (x in m) {}
		
	static public inline function imapk<A>(m:Map<Int, A>)
		for (x in m.keys()) {}
}