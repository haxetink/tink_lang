package tink.lang.macros;

import haxe.macro.Expr;
import haxe.ds.Option;
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
				case macro _: Success(None);
				case macro $i{v} if (v.charAt(0) == '_' && v.charCodeAt(1) <= '9'.code):
					Success(Some(Std.parseInt(v.substr(1))));
				case macro []: 
					arg.reject('At least one expression needed');
				case macro [$a{args}] if (Lambda.foreach(args, Exprs.isWildcard)):
					Success(Some(args.length));
				default: 
					arg.pos.makeFailure('Unsuitable switch argument');
			}
	
	static function returnIfNotVoid(old:Expr)
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
	
	static function parseSwitch(arg, cases, edef, e, ?isFunction):Expr
		return
			switch parseArg(arg) {
				case Success(o):
					var tuple = false;
					var count = 1;
					switch o {
						case Some(c):
							tuple = true;
							count = c;
						default:
					}
					var tmps = [for (i in 0...count) MacroApi.tempName().resolve()];
					var body = ESwitch(tuple ? tmps.toArray() : tmps[0], cases, edef).at(e.pos);
					process(
						if (isFunction == null)
							macro @:pos(e.pos) [$a{tmps}] => $body
						else if (isFunction)
							macro @:pos(e.pos) @f($a{tmps}) $body
						else
							macro @:pos(e.pos) @do($a{tmps}) $body
					);
				default: e;
			}
	
	static public function process(e:Expr) 
		return
			switch e {
				case { expr:ESwitch(arg, cases, edef) }:	
					parseSwitch(arg, cases, edef, e);
				case macro @do ${{ expr:ESwitch(arg, cases, edef) }}:	
					parseSwitch(arg, cases, edef, e, false);
				case macro @f ${{ expr:ESwitch(arg, cases, edef) }}:	
					parseSwitch(arg, cases, edef, e, true);
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