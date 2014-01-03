package ;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;
#end
class Loops {
	macro static public function run() {
		var offset = macro haxe.Timer.delay;
		
		if (!offset.typeof().isSuccess() || Context.defined('java'))
			offset = macro function (f, _) f();
		var factor = 
			if (Context.defined('loop_factor'))
				Std.parseInt(Context.definedValue('loop_factor'));
				else 1;
		function makeClass() {
			var ret = macro class {
				var a:Array<String>;
				var l:List<String>;
				var sm:Map<String, String>;
				var im:Map<Int, String>;
				public function new() {
					a = [for (i in 0...100) Std.string(i)];
					l = Lambda.list(a);
					sm = [for (x in a) x => x];
					im = [for (x in a) Std.parseInt(x) => x];
				}
			};
			var fieldNames = [];
			function add(name:String, ?isPublic:Bool, body:Expr)
				ret.fields.push({
					pos: body.pos,
					name: name,
					access: if (isPublic) [APublic] else null,
					kind: FFun(body.func(false)),
				});
			
			function loop(count:Int, name:String, target:Expr) {
				var fname = MacroApi.tempName();
				fieldNames.push(fname);
				add(fname, macro {
					var start = haxe.Timer.stamp();
					for (i in 0...$v{count})
						for (v in $target) {};
					return { op: $v{name}, time: 1000000 * (haxe.Timer.stamp() - start) / $v{count} };
				});
			}
			
			loop(factor * 10000, 'array', macro a);
			loop(factor * 5000, 'list', macro l);
			loop(factor * 1000, 'string map', macro sm);
			loop(factor * 1000, 'string map keys', macro sm.keys());
			loop(factor * 1000, 'int map', macro im);
			loop(factor * 1000, 'int map keys', macro im.keys());
			
			var calls = [for (f in fieldNames) 
				macro tink.core.Future.async(function (cb) $offset(function () cb($i{f}()), 1))
			];
			add('run', macro return tink.core.Future.ofMany([$a{calls}]));
			
			return ret;
		}
		var plain = makeClass();
		plain.name = 'Plain';
		var tink = makeClass();
		tink.name = 'Tink';
		
		switch tink.kind {
			case TDClass(_, interfaces, _):
				interfaces.push('tink.Lang'.asTypePath());
			default:
		}
		
		Context.defineType(plain);
		Context.defineType(tink);

		return macro 
			new Tink().run() >> function (tink) return 
			new Plain().run() >> function (plain) return 
				{ tink: tink, plain: plain };
		}
}