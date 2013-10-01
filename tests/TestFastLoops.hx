package ;

import tink.lang.Sugar;

class TestFastLoops extends Base implements Sugar {
	function testArray() {
		var a = [for (i in 0...100) Std.string(i)],
			count = 5000;
		var l = Lambda.list(a),
			sm = @:diet [for (x in a) x => x],
			im = @:diet [for (x in a) Std.parseInt(x) => x];
		
		@measure('tink array' * (count * 20)) Tink.array(a);
		@measure('haxe array' * (count * 20)) Haxe.array(a);
		
		@measure('tink list' * (count * 20)) Tink.list(l);
		@measure('haxe list' * (count * 20)) Haxe.list(l);
		
		@measure('tink smap' * count) Tink.smap(sm);
		@measure('haxe smap' * count) Haxe.smap(sm);
		
		@measure('tink smapk' * count) Tink.smapk(sm);
		@measure('haxe smapk' * count) Haxe.smapk(sm);
		
		@measure('tink imap' * count) Tink.imap(im);
		@measure('haxe imap' * count) Haxe.imap(im);
		
		@measure('tink imapk' * count) Tink.imapk(im);
		@measure('haxe imapk' * count) Haxe.imapk(im);
		
		for ([x in a, i in 0...a.length])
			assertEquals(Std.string(i), x);
			
		for ([x in l, i in 0...l.length])
			assertEquals(Std.string(i), x);
	}
}

class Tink implements Sugar {		
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