package tink.lang.macros;

import haxe.macro.Expr;

import tink.macro.*;
using tink.macro.Tools;

class Dispatch {
	static var types = [
		':signal' => {
			published: function (t) return macro : tink.core.Signal<$t>,
			internal: function (pos, t) return macro @:pos(pos) new tink.core.Callback.CallbackList<$t>()
		},
		':future' => {
			published: function (t) return macro : tink.core.Future<$t>,
			internal: function (pos, t) return macro @:pos(pos) tink.core.Future.create()
		}
	];
	static public function members(ctx:ClassBuilder) {
		for (type in types.keys()) {
			var make = types.get(type);
			for (member in ctx) 	
				switch (member.extractMeta(type)) {
					case Success(tag):
						switch (member.kind) {
							case FVar(t, e):
								if (t == null)
									t = if (e == null) macro : tink.core.Signal.Noise;
										else e.pos.makeBlankType();
								member.publish();
								if (e == null) {	
									var own = '_' + member.name;
									ctx.addMember( {
										name: own,
										kind: FVar(null, make.internal(tag.pos, t)),
										pos: tag.pos
									}, true).isPublic = false;	
									e = 
										if (type == ':signal')
											macro @:pos(tag.pos) $i{own}.toSignal();
										else
											macro @:pos(tag.pos) $i{own}.asFuture();
								}
								//TODO: it's probably better to expose the signal through a getter
								member.kind = FProp('default', 'null', make.published(t), e);
							default:
								member.pos.error('can only declare signals on variables');
						}
					default:
				}
		}
	}	
	static public function normalize(e:Expr)
		return switch e {
			case macro @until($a{args}) $handler:
				macro @:pos(e.pos) @when($a{args}) $handler;
			default: e;	
		}
	static var DISPATCHER = macro tink.lang.helpers.StringDispatcher;
	static public function on(e:Expr) 
		return
			switch e {
				case macro @when($a{args}) $handler:
					if (args.length == 0)
						e.reject('At least one signal/event/future expected');
					var ret = [for (arg in args) 
						switch arg {
							case macro @capture $dispatcher[$event]
								,macro $dispatcher[@capture $event]:
								//TODO: allow for Iterable<String>
								macro @:pos(arg.pos) 
									$DISPATCHER.capture($DISPATCHER.promote($dispatcher), $event, ___h);
							case macro $dispatcher[$event]:
								macro @:pos(arg.pos) 
									$DISPATCHER.promote($dispatcher).watch($event, ___h);
							default:
								macro @:pos(arg.pos) $arg.when(___h);
								//macro @:pos(arg.pos) tink.core.Callback.target($arg)(___h);
						}
					].toArray();
					macro (function (___h) return $ret)($handler);//TODO: SIAF only generated because otherwise inference order will cause compiler error
				default: e;
			}
			
	static public function with(e:Expr) 
		return switch e {
			case macro @with($target) $handle:
				function transform(e:Expr) return switch e {
					case macro @with($_) $_: e;
					case macro @when($a{args}) $handler:
						args = 
							[for (arg in args) 
								switch arg.typeof() {
									case Success(t) if (t.getID() == 'String'):
										switch arg {
											case macro @capture $event: 
												macro @:pos(arg.pos) @capture ___t[$event];
											case event: 
												macro @:pos(arg.pos) ___t[$event];
										}
									default:
										switch arg {
											case macro $i{name}: 
												macro @:pos(arg.pos) ___t.$name;
											case macro $i{name}($a{args}): 
												macro @:pos(arg.pos) ___t.$name($a{args});
											default: arg;
										}
								}
							];
						handler = transform(handler);
						macro @when($a{args}) $handler;
					default: e.map(transform);
				}
				macro {
					var ___t = $target;
					${transform(handle)};
					___t;
				}
			default: e;
		}
}