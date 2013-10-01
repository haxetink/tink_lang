package tink.lang.macros;

import haxe.macro.Expr;
using tink.MacroApi;

class ShortLambda {
	static public function postfix(e:Expr) 
		return
			switch e {
				case macro $callee($a{args}) => $callback:
					macro @:pos(e.pos) $callee($a{args.concat([callback])});
				default: e;	
			}
	
	static public function protectMaps(e:Expr)
		return
			switch e {
				case macro [$a{args}] if (args.length > 0 && switch args[0] { case macro $k => $v: true; default: false; }):
					[for (a in args)
						switch a {
							case macro $k => $v:
								macro ($k) => $v;
							default: a;
						}
					].toArray();
				default: e;
			}
	
	static public function process(e:Expr) 
		return
			switch e {
				case { expr: EMeta({ name: tag, params: [], pos: mpos }, { expr:ESwitch(macro _, cases, edef), pos:pos }) } if (tag == 'do' || tag == 'f'):
					var tmp = MacroApi.tempName();
					process(EMeta( 
						{ name: tag, params: [tmp.resolve()], pos: mpos },
						ESwitch(tmp.resolve(), cases, edef).at(pos)
					).at(e.pos));
					
				case macro ![$a{args}] => $body
					,macro @do($a{args}) $body:	
					var nuargs = [];
					
					for (arg in args)
						switch arg {
							case { expr: EVars(vars) }:
								for (v in vars) 
									nuargs.push(v.name.toArg(v.type, v.expr));
							case macro $i{name}: 
								nuargs.push(name.toArg());
							default: arg.reject('expected identifier or variable declaration');	
						}
					
					body.func(nuargs, false).asExpr(e.pos);
					
				case macro [$a{args}] => $body
					,macro @f($a{args}) $body:
					
					body.func([
						for (arg in args)
							arg.getIdent().sure().toArg()
					], true).asExpr(e.pos);
					
				default: e;
			}
}