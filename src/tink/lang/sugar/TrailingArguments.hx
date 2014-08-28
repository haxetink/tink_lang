package tink.lang.sugar;

import haxe.macro.Expr;
import haxe.ds.Option;
using tink.MacroApi;

class TrailingArguments {
	static public function apply(e:Expr) 
		return
			switch e {
				case macro $callee($a{args}) => $callback:
					macro @:pos(e.pos) $callee($a{args.concat([callback])});
				default: e;	
			}
}