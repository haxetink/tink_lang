package tink.lang.macros;

import tink.macro.*;
import haxe.macro.Type;
import haxe.macro.Expr;

using tink.MacroApi;

private abstract Fieldish({ set: String->Bool->Expr->Void }) {
	function new(set) this = { set: set };
	public function set(name, single, expr)
		this.set(name, single, expr);
		
	@:from static function ofMember(m:Member) 
		return new Fieldish(function (name, single, expr:Expr) {
			if (single)
				while (m.extractMeta(name).isSuccess()) {}
			m.addMeta(name, expr.pos, [expr]);
		});
		
	@:from static function ofClassField(f:ClassField) 
		return new Fieldish(function (name, single, expr:Expr) {
			if (single && f.meta.has(name))
				f.meta.remove(name);
			f.meta.add(name, [expr], expr.pos);
		});
	
}

class PartialImpl {
	
	static inline var DEFAULT = ':defaultImplementation';
	static inline var REQUIRES = ':defaultRequires';
	
	static function getDefault(f:ClassField) 
		return
			switch f.meta.get().getValues(DEFAULT) {
				case []: null;
				case [[ret]]: ret;
				default: f.pos.error('multiple defaults defined');
			}
	
	static public function addDependency(f:Fieldish, fields:Array<Member>) {
		var t = TAnonymous(fields);
		f.set(REQUIRES, false, macro cast(null, $t));//TODO: check this causes no problems with compiler cache
	}
	
	static public function setDefault(f:Fieldish, expr:Expr) 
		f.set(DEFAULT, true, expr);
	
	static public function process(ctx:ClassBuilder) {
		if (ctx.target.isInterface) 
			for (m in ctx) 
				switch m.extractMeta(':usedOnlyBy') {
					case Success(tag):
					default:
						switch m.kind {
							case FFun(f):
								if (f.expr != null) {
									m.addMeta(DEFAULT, f.expr.pos, [Reflect.copy(f).asExpr()]);
									f.expr = null;
								}
							default:
						}
				}
		else 
			for (i in ctx.target.interfaces)
				for (f in TInst(i.t, i.params).getFields(true).sure()) {
					var index = 0,
						paramMap = new Map();
					for (p in i.t.get().params)
						paramMap.set(p.name, i.params[index++].toComplex());
					if (!ctx.hasMember(f.name)) {
						switch (f.kind) {
							case FVar(read, write):
								ctx.addMember({
									name: f.name,
									access: f.isPublic ? [APublic] : [APrivate],
									kind: FProp(read.accessToName(), write.accessToName(true), f.type.toComplex()),
									pos: f.pos
								});
								var d = getDefault(f).substParams(paramMap);
								if (d != null) 
									switch (d.expr) {
										case ECheckType(e, t):
											Init.field(ctx.getConstructor(), f.name, t, e);
										default:
											Init.field(ctx.getConstructor(), f.name, f.type.toComplex(), d);//for people who specify this manually
									}
							case FMethod(_):
								var d = getDefault(f).substParams(paramMap);
								if (d != null) {
									switch (d.expr) {
										case EFunction(_, impl):
											ctx.addMember({
												name: f.name,
												access: f.isPublic ? [APublic] : [APrivate],
												kind: FFun(impl),
												pos: f.pos
											});									
										default:
											d.reject();
									}
								}
								
						}
					}
				}
	}	
}