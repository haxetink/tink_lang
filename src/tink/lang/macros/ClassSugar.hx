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
		static function simpleSugar(rule:Expr->Expr, ?outsideIn = false) {
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
			
		static function syntax(rule:Expr->Expr) 
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
								e.expr = rule(e).expr;//RAPTORS
					}
			}
		
		//TODO: it seems a little monolithic to yank all plugins here
		static public var PLUGINS = [
			// simpleSugar(LoopSugar.fold),
			//  // #if (tink_reactive || !tink_core) 
			// 	// tink.reactive.bindings.macros.BindableProperties.cache,
			// // #end
			Dispatch.members,
			Init.process,
			Forward.process,
			PropBuilder.process,
			// #if (tink_reactive || !tink_core)
			// 	tink.reactive.bindings.macros.BindableProperties.make,
			// #else
			// 	noBindings,
			// #end
			syntax(Pipelining.shortBind),
			
			simpleSugar(function (e) return switch e {
				case macro @in($delta) $handler:
					return ECheckType(
						(macro @:pos(e.pos) haxe.Timer.delay($handler, Std.int($delta * 1000)).stop),
						macro : tink.core.types.Callback.CallbackLink
					).at(e.pos);
				default: e;				
			}),
			
			simpleSugar(ShortLambda.protectMaps),
			simpleSugar(ShortLambda.process),
			simpleSugar(ShortLambda.postfix),
			
			simpleSugar(Dispatch.normalize),
			simpleSugar(Dispatch.with),
			simpleSugar(Dispatch.on),
			
			simpleSugar(function (e) return switch e { 
				case (macro $val || if ($x) $def else $none)
					,(macro $val | if ($x) $def else $none) if (none == null):
					macro @:pos(e.pos) {
						var ___val = $val;
						(___val == $x ? $def : ___val);
					}
				default: e;
			}),
			// // simpleSugar(tink.markup.formats.Fast.build),
			// // simpleSugar(tink.markup.formats.Dom.build),
			simpleSugar(Pipelining.transform, true),
			simpleSugar(DevTools.log, true),
			simpleSugar(DevTools.measure),
			simpleSugar(DevTools.explain),
			PartialImpl.process,
			simpleSugar(LoopSugar.comprehension),
			simpleSugar(LoopSugar.transformLoop),
		];	
	#end
}