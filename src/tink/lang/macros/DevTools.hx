package tink.lang.macros;

import haxe.macro.Expr;

using tink.MacroApi;

class DevTools {
	
	static public function explain(e:Expr)
		return switch e {
			case macro @:explain $e: e.log();
			default: e;
		}
		
	static public function log(e:Expr) 
		return switch e {
			case macro @log($a{args}) $value:				
				if (args.length > 0)
					args[0].pos.warning('arguments will be ignored');
				return macro @:pos(e.pos) {
					var x = $value;
					trace($v{value.toString()} + ': ' + x);
					x;
				}
			default: e;
		}
		
	static public function measure(e:Expr) 
		return switch e {
			case macro @measure($a{args}) $value:			
				var name = 
					switch args.length {
						case 0: e.toString().toExpr();
						case 1: args[0];
						default: args[1].reject('too many arguments');
					}
				var count = 
					switch name {
						case macro $n * $count:
							name = macro $n + ' * ' + $count;
							count;
						default: 1.toExpr();
					}
				return (macro @:pos(e.pos) {
					var start = haxe.Timer.stamp(),
						name = $name,
						value = {
							for (___i in 0...$count - 1) $value; 
							[($value)];//deals with Void
						}
					trace(name + ' took ' + Std.int(1000 * (haxe.Timer.stamp() - start)) + ' msecs');
					value[0];
				});
			default: e;	
		}
}