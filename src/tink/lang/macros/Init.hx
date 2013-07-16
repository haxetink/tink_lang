package tink.lang.macros;

import haxe.macro.Expr;
import tink.macro.*;

using tink.macro.Tools;

class Init {
	static public function process(ctx) 
		new Init(ctx).processMembers();
	
	var ctx:ClassBuilder;
	function new(ctx) 
		this.ctx = ctx;
	
	function getType(t:Null<ComplexType>, inferFrom:Expr) 
		return
			if (t == null) 
				inferFrom.typeof().sure().toComplex(true);
			else 
				t;

	function processMembers() 
		for (member in ctx) {
			if (!member.isStatic)
				switch (member.kind) {
					case FVar(t, e):
						if (e != null) {
							member.kind = FVar(t = getType(t, e), null);
							Init.member(ctx, member, t, e);
						}
					case FProp(get, set, t, e):
						if (e != null) {
							member.kind = FProp(get, set, t = getType(t, e), null);
							Init.member(ctx, member, t, e);
						}						
					default:
				}
		}
		
	static public function member(ctx:ClassBuilder, member:Member, t:ComplexType, e:Expr) 
		if (ctx.target.isInterface) 
			member.addMeta(':default', e.pos, [ECheckType(e, t).at(e.pos)]);
		else 
			field(ctx.getConstructor(), member.name, t, e);
	
	//TODO: the naming here is quite horrible
	static public function field(ctor:Constructor, name, t:ComplexType, e:Expr) {
		var init = null,
			def = null;
		if (!e.isWildcard())
			switch (e.expr) {
				case EParenthesis(e): def = e;
				default: init = e;
			}
		ctor.init(name, e.pos, init, def, t);							
	}
}