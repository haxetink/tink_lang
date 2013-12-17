package tink.lang.helpers;

@:native('$loops')
class LoopHelpers {
	#if js
	static public function ik<A>(target:haxe.ds.IntMap<A>):Array<Int> untyped {
		var ret = [];
        __js__("for( var f in target.h ) {");
        if( f.charCodeAt(0) < 58) ret.push(parseInt(f));
        __js__("}");
        return ret;
	}	
	static public function sk<A>(target:haxe.ds.StringMap<A>):Array<String> untyped {
		var ret = [];
        __js__("for( var f in target.h ) {");
        if( f.charAt(0) == '$') ret.push(f.substr(1));
        __js__("}");
        return ret;
	}
	static public function skd<A>(target:haxe.ds.StringMap<A>):Array<String> untyped {
		var ret = [];
        __js__("for( var f in target.h ) {");
        if( f.charAt(0) == '$') ret.push(f);
        __js__("}");
        return ret;
	}
	#end
}