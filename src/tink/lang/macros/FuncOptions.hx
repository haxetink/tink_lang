package tink.lang.macros;

import haxe.macro.Expr;
import tink.macro.*;
using tink.CoreApi;
using tink.MacroApi;

class FuncOptions {
	static public function process(c:ClassBuilder) {
		for (m in c)
			switch m.getFunction() {
				case Success(f):
					options(f, m.pos);
				default:
			}
	}
	static function options(f:Function, pos:Position) {
		var body = Lazy.ofFunc(function ()
			return
				if (f.expr == null) [];
				else switch f.expr.expr {
					case EBlock(body): body;
					default:
						var body = [f.expr];
						f.expr = body.toMBlock();
						body;
				}
		);
		
		function prepend(e) 
			body.get().unshift(e);
		
		var args = f.args.copy();
		args.reverse();
		for (arg in args)
			if (arg.value != null) 
				switch arg.value.expr {
					case EArrayDecl(parts):
						var opt = true,
							fields = new Array<Field>();
						function add(pos, name, type, init) {
							if (init == null) 
								opt = false;
							else 
								prepend(macro @:pos(pos) if ($i{arg.name}.$name == null) $i{arg.name}.$name = ${init});
							if (type == null)
								type = 
									if (init != null)
										init.typeof().map(Types.toComplex.bind(_, { direct: true })).orUse(pos.makeBlankType());
									else
										pos.makeBlankType();
							fields.push({
								name: name,
								pos: pos,
								kind: FVar(type),
								meta: if (init == null) null else [{ name : ':optional', pos: pos, params: [] }]
							});
						}
						parts.reverse();
						for (p in parts)
							switch p {
								case macro var $name:$type = $init:
									add(p.pos, name, type, init);
								case macro $i{name} = $init:
									add(p.pos, name, null, init);
								default:
									p.reject();
							}
							
						if (opt) {
							prepend(macro if ($i{arg.name} == null) $i{arg.name} = {});
							arg.opt = true;
						}
						arg.type = TAnonymous(fields); //TODO: we could trick the typer into looking over the body
						arg.value = null;
					default:
				}
	}
}