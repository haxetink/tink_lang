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
	
	static function parseArg(arg:Expr) 
		return
			switch arg {
				case macro _: Success(1);
				case macro []: arg.reject('At least one expression needed');
				case macro [$a{args}] if (Lambda.foreach(args, Exprs.isWildcard)):
					Success(args.length);
				default: arg.pos.makeFailure('Unsuitable switch argument');
			}
	
	static function returnIfNotVoid(old:Expr) //pattern matcher seems to mingle the expression beyond recognition
		return
			if (old.typeof().sure().getID() == 'Void') old;
			else
				old.yield(function (e) return macro @:pos(old.pos) return $e, { leaveLoops : true });
				
	static function arrow(args, body:Expr) 
		return body.bounceExpr(returnIfNotVoid).func(args, false).asExpr();
	
	static function getIdents(exprs:Array<Expr>)
		return [
			for (e in exprs)
				e.getIdent().sure().toArg()
		];
	
	static public function process(e:Expr) 
		return
			switch e {
				case { expr:ESwitch(arg, cases, edef), pos:pos }:					
					switch parseArg(arg) {
						case Success(count):
							var tmps = [for (i in 0...count) MacroApi.tempName().resolve()];
							process(
								macro @:pos(pos) [$a{tmps}] => ${ESwitch(tmps.toArray(), cases, edef).at(pos)}
							);
						default: e;
					}
				case macro [$a{args}] => $body:
					arrow(getIdents(args), body);
				case macro $i{arg} => $body:
					arrow([arg.toArg()], body);
				case macro @do($a{args}) $body:
					body.func(getIdents(args), false).asExpr(e.pos);
				case macro @f($a{args}) $body:
					body.func(getIdents(args), true).asExpr(e.pos);
				default: e;
			}
}