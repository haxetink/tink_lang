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
					case EObjectDecl(parts):
						var opt = true,
							fields = new Array<Field>(),
							direct = arg.name == '_';
							
						if (direct)	
							arg.name = MacroApi.tempName();
							
						function add(pos, name, init:Expr) {
							if (init.isWildcard())
								init = null;
								
							if (init == null) 
								opt = false;
								
							if (direct) 
								if (init == null)
									prepend(macro @:pos(pos) var $name = $i{arg.name}.$name);
								else
									prepend(macro @:pos(pos) var $name = if ($i{arg.name}.$name == null) $init else $i{arg.name}.$name);
							else
								if (init == null) 
									opt = false;
								else 
									prepend(macro @:pos(pos) if ($i{arg.name}.$name == null) $i{arg.name}.$name = ${init});
								
							var type = 
								switch init {
									case null: 
										pos.makeBlankType();
									case macro ($_ : $t):
										t;
									default:
										init.typeof().map(Types.toComplex.bind(_, { direct: true })).orUse(pos.makeBlankType());
								}
									
										
							type = macro : Null<$type>;
							fields.push({
								name: name,
								pos: pos,
								kind: FVar(type),
								meta: if (init == null) null else [{ name : ':optional', pos: pos, params: [] }]
							});
						}
						parts.reverse();
						for (f in parts)
							add(f.expr.pos, f.field, f.expr);
							
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