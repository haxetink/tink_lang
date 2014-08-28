package tink.lang;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.lang.sugar.*;
	import tink.macro.ClassBuilder;
	import tink.priority.Queue;
	
	using tink.MacroApi;
	using tink.CoreApi;
#end
	
	
typedef Plugin = Callback<ClassBuilder>;

class Sugar {
	macro static public function apply():Array<Field> 
		return 
			ClassBuilder.run(
				classLevel,
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
		
		static function anyAwaits(e:Array<Expr>) {
			for (e in e)
				switch e {
					case macro @await $_: return true;
					default:
				}
			return false;
		}
		static function cps(e:Expr)
			return
				switch e {
					case macro $callee($a{args}) if (anyAwaits([callee].concat(args))):
						var accumulated = [];
						
						var ret = 
							switch callee {
								case macro @await $e:
									macro @:pos(e.pos) 
										$e.handle(function (__callee) {
											__callee($a{accumulated});
										});
								default:
									macro @:pos(e.pos) $callee($a{accumulated});
							}						
						
						args = args.copy();
						args.reverse();
						
						for (e in args) {
							
							var tmp = MacroApi.tempName();
							accumulated.unshift(tmp.resolve(e.pos));
							
							ret = switch e {
								case macro @await $e:
									macro @:pos(e.pos) $e.handle(function ($tmp) $ret);
								default: 
									macro @:pos(e.pos) {
										var $tmp = e;
										$ret;
									}
							}
						}
						e;
					default: e;
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
			
		static function switchArrayRest(e:Expr)
			return switch e.expr {
				case ESwitch(_, cases, _):
					for (c in cases)
						c.values = [for (v in c.values) 
							v.transform(function (e:Expr) 
								return switch e.expr {
									case EArrayDecl(v) if (v.length > 0):
										for (i in 0...v.length)
											switch v[i] {
												case macro @rest $i{name}:
													var head = v.slice(0, i);
													var tail = v.slice(i + 1);
													
													e = (macro { 
														head: _.slice(0, $v{head.length}), 
														rest: _.slice($v{head.length}, _.length - $v{tail.length}),
														tail: _.slice(_.length - $v{tail.length}),
													} => {
														rest: $i{name},
														head: $a{head},
														tail: $a{tail},
													});
												default:
											}
										e;
									default:
										e;
								}
							)
						];
					e;
				default: e;
			}
				
		static var expressionLevel = new Queue<Expr->Expr>();	
		
		static var classLevel = {
			
			var ret = new Queue();
			
			function queue<T>(queue:Queue<T>, items:Array<Pair<String, T>>) {				
				var first = items.shift();
				queue.whenever(first.b, first.a);
				var last = first.a;
				for (item in items) 
					queue.after(last, item.b, last = item.a);
			}
			
			function p<X>(a:String, b:X)
				return new Pair('tink.lang.sugar.$a', b);
			
			queue(ret, [
				p('ShortLambdas::protectMaps', simpleSugar(ShortLambdas.protectMaps)),
			
				p('Notifiers', Notifiers.apply),
				p('PropertyNotation', PropertyNotation.apply),
				p('DirectInitialization', DirectInitialization.process),
				p('Forwarding', Forwarding.apply),
				
				new Pair('tink.lang.Sugar::expressionLevel', simpleSugar(function (e:Expr) {
					for (rule in expressionLevel)
						e = rule(e);
					return e;
				}, true)),
				
				p('ComplexDefaultArguments', ComplexDefaultArguments.apply),
				
				p('PartialImplementation', PartialImplementation.apply),
				
				p('ExtendedLoops::secondPass', simpleSugar(ExtendedLoops.secondPass)),
			]);
			
			queue(expressionLevel, [
				p('shortcuts', shortcuts),
				p('switchArrayRest', switchArrayRest),
				
				p('ExtendedLoops::comprehensions', ExtendedLoops.comprehensions),
				p('ExtendedLoops::firstPass', ExtendedLoops.firstPass),
				
				p('ShortLambdas::process', ShortLambdas.process),
				p('ShortLambdas::postfix', ShortLambdas.postfix),
				
				p('Default', defaultVal),
			]);
			
			ret;
		}	
	#end
}