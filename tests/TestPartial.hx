package ;

import tink.Lang;

interface Enumerable<T> extends tink.Lang {
	var length(get, never):Int;
	@:usedOnlyBy(iterator) 
	var elements:Array<T> = _;
	@:usedOnlyBy(forEach) 
	public function iterator():Iterator<T> {
		return elements.iterator();
	}	
	private function get_length():Int
		return fold(0, function (count, _) return count + 1);
		
	function fold<A>(init:A, calc:A->T->A):A {
		forEach(function (v) init = calc(init, v));
		return init;
	}
	function forEach(f:T->Void):Void {
		for (v in this)
			f(v);
	}
	function map<A>(f:T->A):Array<A> {
		var ret:Array<A> = [];
		forEach(function (x) ret.push(f(x)));
		return ret;
	}
	function filter<A>(f:T->Bool):Array<T> {
		var ret = [];
		forEach(function (v) if (f(v)) ret.push(v));
		return ret;
	}
}

private class Default<X> implements Enumerable<X> {
	
}

private class Empty<Y> implements Enumerable<Y> {
	public function new() {}
	public function forEach(f:Y->Void) {}
}

private class EmptyIterable<Y> implements Enumerable<Y> {
	public function new() {}
	public function iterator():Iterator<Y>
		return {
			hasNext: function () return false,
			next: function () return throw 'assert'
		}
}


private class Single<Z> implements Enumerable<Z> {
	var value:Z = _;
	public function forEach(f:Z->Void) f(value);
}

private class SingleIterable<Z> implements Enumerable<Z> {
	var value:Z = _;
	public function iterator() {
		var first = true;
		return {
			hasNext: function () 
				return
					if (first) {
						first = false;
						true;
					}
					else false,
			next: function () return value
		}
	}
}

class TestPartial extends Base {
	function test() {
		var d = new Default([1, 2, 3]),
			e = new Empty(),
			ei = new EmptyIterable(),
			s = new Single(4),
			si = new SingleIterable(5);
		
		var results = [];
		
		for (i in d)
			results.push(i);
			
		for (i in ei)
			results.push(i);
			
		for (i in si)
			results.push(i);
			
		assertEquals('1,2,3,5', results.join(','));
		
		results = [];
		
		for (enumerable in [d, e, ei, s, si])
			enumerable.forEach(results.push);
			
		assertEquals('1,2,3,4,5', results.join(','));
	}
}