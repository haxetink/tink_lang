package tink.lang.macros;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.lang.macros.LoopSugar;
	import tink.macro.ClassBuilder;
	
	using tink.MacroApi;
#end
	
class ClassSugar {
	macro static public function process():Array<Field> 
		return 
			ClassBuilder.run(
				PLUGINS,
				Context.getLocalClass().get().meta.get().getValues(':verbose').length > 0
			);
	
	#if macro
		static public function simpleSugar(rule:Expr->Expr, ?outsideIn = false) {
			function transform(e:Expr) {
				return 
					if (e == null || e.expr == null) e;
					else 
						switch (e.expr) {
							case EMeta( { name: ':diet' }, _): e;
							default: 
								if (outsideIn) 
									rule(e).map(transform);
								else 
									rule(e.map(transform));
						}
			}
			return syntax(transform);
		}
		
		static public function syntax(rule:Expr->Expr) 
			return function (ctx:ClassBuilder) {
				function transform(f:Function)
					if (f.expr != null)
						f.expr = rule(f.expr);
				ctx.getConstructor().onGenerate(transform);
				for (m in ctx)
					switch m.kind {
						case FFun(f): transform(f);
						case FProp(_, _, _, e), FVar(_, e): 
							if (e != null)
								e.expr = rule(e).expr;//TODO: it might be better to just create a new kind, rather than modifying the expression in place
					}
			}
		
		static function shortcuts(e:Expr)
			return switch e {
				case macro @until($future) $link:
					
					shortcuts(macro @:pos(e.pos) @when($future) ($link : tink.core.Callback.CallbackLink));
					
				case macro @when($future) $handler:
					var any = e.pos.makeBlankType();
					macro @:pos(e.pos) ($future : tink.core.Future<$any>).handle($handler);
					
				case macro @whenever($signal) $handler:
					var any = e.pos.makeBlankType();
					macro @:pos(e.pos) ($signal : tink.core.Signal<$any>).handle($handler);
				
				case macro @in($delta) $handler:
				
					macro @:pos(e.pos) (
						haxe.Timer.delay($handler, Std.int($delta * 1000)).stop :
						tink.core.Callback.CallbackLink
					);
					
				case macro @every($delta) $handler:
				
					macro @:pos(e.pos) (
						{
							var t = new haxe.Timer(Std.int($delta * 1000));
							t.run = $handler;
							t.stop;
						} : tink.core.Callback.CallbackLink
					);
				
				default: e;
			}
			
		static function defaultVal(e:Expr)
			return switch e { 
				case (macro $val || if ($x) $def)
					,(macro $val | if ($x) $def):
					macro @:pos(e.pos) {
						var ___val = $val;
						(___val == $x ? $def : ___val);
					}
				default: e;
			}
				
		//TODO: it seems a little monolithic to yank all plugins here
		static var PLUGINS = [
			simpleSugar(ShortLambda.protectMaps),
			
			FuncOptions.process,
			Dispatch.members,
			PropBuilder.process,
			Init.process,
			Forward.process,
			
			simpleSugar(shortcuts),
			
			simpleSugar(LoopSugar.comprehension),
			simpleSugar(LoopSugar.firstPass),
			
			simpleSugar(ShortLambda.process, true),
			simpleSugar(ShortLambda.postfix),
			
			simpleSugar(defaultVal),
			PartialImpl.process,
			
			simpleSugar(LoopSugar.secondPass),
		];	
	#end
}