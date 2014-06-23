package tink.lang.sugar;

import haxe.macro.Expr;
using tink.MacroApi;

typedef CustomIterator = {
	init: LoopSetup,
	hasNext: Expr,
	next: Expr
}

class LoopSetup {
	public var def:Array<Var>;
	public var set:Array<Expr>;
	public var pre:Int;
	// public var first:Array<Var>;
	public function new(?def, ?set, ?pre) {
		this.def = if (def != null) def else [];
		this.set = if (set != null) set else [];
		this.pre = if (pre != null) pre else 0;
	}
	
	public function define(name:String, ?type, ?expr) {
		this.def.push({ name: name, type: type, expr: expr });
		return this;
	}
	
	public function definePre(name:String, ?type, ?expr) {
		this.def.unshift({ name: name, type: type, expr: expr });
		pre++;
		return this;
	}
	
	public function concat(that:LoopSetup) {
		var ret = new LoopSetup(
			this.def.slice(0, this.pre)
				.concat(that.def.slice(0, that.pre))
				.concat(this.def.slice(this.pre))
				.concat(that.def.slice(that.pre)),
			set.concat(that.set)
		);
		return ret;
	}
	
	public function toExprs() 
		return (
			if (pre > 0) [EVars(def.slice(0, pre)).at()]
			else []
		).concat([EVars(def.slice(pre)).at(), set.toBlock()]);
}