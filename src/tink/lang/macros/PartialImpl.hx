package tink.lang.macros;

import tink.macro.*;
import haxe.macro.Type;
import haxe.macro.Expr;

using tink.macro.Tools;

class PartialImpl {
	static function getDefault(f:ClassField) {
		var tags = f.meta.get().getValues(':default');
		return
			switch (tags.length) {
				case 0: null;
				case 1: tags[0][0];
				default: f.pos.error('multiple defaults defined');
			}
	}
	static function addRequirements(f:ClassField, ctx:ClassBuilder) {
		var tags = f.meta.get().getValues(':defaultRequires');
		switch (tags.length) {
			case 0: null;
			case 1: 
				switch (tags[0]) {
					case [ { expr: ECast(_, TAnonymous(fields)) } ]: 
						for (f in fields)
							if (!ctx.hasMember(f.name))
								ctx.addMember(f);
					default: 
						throw 'assert';
				}
			default: f.pos.error('multiple default requirements defined');
		}		
	}
	static public function process(ctx:ClassBuilder) {
		if (ctx.target.isInterface) 
			for (m in ctx) 
				switch (m.kind) {
					case FFun(f):
						if (f.expr != null) {
							m.addMeta(':default', f.expr.pos, [EFunction(null, Reflect.copy(f)).at(f.expr.pos)]);
							f.expr = null;
						}
					default:
				}
		else 
			for (i in ctx.target.interfaces)
				for (f in TInst(i.t, i.params).getFields(true).sure()) {
					var index = 0,
						paramMap = new Map();
					for (p in i.t.get().params)
						paramMap.set(p.name, i.params[index].toComplex(true));
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
								if (d != null) {
									addRequirements(f, ctx);
									switch (d.expr) {
										case ECheckType(e, t):
											Init.field(ctx.getConstructor(), f.name, t, e);
										default:
											Init.field(ctx.getConstructor(), f.name, f.type.toComplex(), d);//for people who specify this manually
									}
								}
							case FMethod(_):
								var d = getDefault(f).substParams(paramMap);
								if (d != null) {
									addRequirements(f, ctx);
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