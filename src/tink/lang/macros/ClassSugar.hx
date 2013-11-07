package tink.lang.macros;

#if macro
	import haxe.macro.Context;
	import haxe.macro.Expr;
	import tink.lang.macros.LoopSugar;
	import tink.macro.ClassBuilder;
	using tink.CoreApi;
	using tink.MacroApi;
	using StringTools;
	
	abstract PluginId(Pair<String, String>) {
		public var lib(get, never):String;
		public var name(get, never):String;
		
		public function new(lib, name) return new Pair(lib, name);
		
		inline function get_lib() return this.a;
		inline function get_name() return this.b;
		
		public function toString()
			return lib.urlEncode() + '/' + name.urlEncode();
		
		@:from static function fromObj(o)
			return new PluginId(o.lib, o.name);
			
		@:from static function fromString(s:String)
			return
				switch s.split('/') {
					case [lib, name]: new PluginId(lib.urlDecode(), name.urlDecode());
					default: throw 'Invalid plugin id $s';
				}
	}
	
	typedef PluginRule = {
		var id(default, null):PluginId;
		var before(default, null):Bool;
		@:optional var separate(default, null):Bool;
	}
	
	private typedef CanonicalRule = {
		first:PluginId,
		then:PluginId,
		separate:Bool,
	}
	
	typedef Plugin = {
		var id(default, null):PluginId;
		@:optional var rules(default, null):Array<PluginRule>;
		var transform(default, null):Expr->Expr;
	}
	
	// typedef SyntaxPlugin = Plugin<Expr->Expr>;
	// typedef 
	
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
		
		
		static var plugins:Array<Plugin> = [];
		static var order = new Map<String, CanonicalRule>();
		static public function addPlugin(p:Plugin) {
			function fullId(p:PluginId)
				return p.lib.urlEncode()+'/'+p.name.urlEncode();
			plugins.push(p);
			for (rule in p.rules) {
				var c = canonical(p, rule);
				var id1 = fullId(c.first),
					id2 = fullId(c.then);
				var fullId = '$id1 -> $id2';
				// var fullId = if (id1 > id2) '$id1 -> $id2' else '$id2 -> $id1';
				order[fullId] = merge(order[fullId], c);
			}
		}
		static function orderPlugins() {
			
			// var lookup = new Map(),
				// offset = 0;
			// var ret = [[]];
			var indices = new Map(),
				index = 0;
			for (p in plugins)
				indices.set(p.id.toString(), index++);
			function index(p:PluginId)
				return indices.get(p.toString());
			var matrix = [for (p in plugins) 
				[for (p in plugins) 0]
			];
			function max(x, y, v) {
				if (x == y) return v;
				var is = matrix[x][y];
				return 
					if (is < v) matrix[x][y] = v;
					else is;
			}
			function log(x:Dynamic)
				Context.currentPos().warning(Std.string(x));
			for (r in order) {
				var first = index(r.first),
					then = index(r.then);
				if (first == null || then == null) continue;
				var delta = max(then, first, if (r.separate) 2 else 1);
				log(r);
				function inc(first, then) {
					var toInc = [];
					
					for (p in 0...then+1)
						if (matrix[first][p] > 0) {
							max(then, p, delta + matrix[first][p] - 1);
							toInc.push(p);
						}
					
					log([[first, then], toInc]);
					
					for (p in toInc)
						inc(p, first);
				}
				inc(first, then);
			}
			throw [for (p in plugins) p.id.toString()] + ':\n' + matrix.join('\n');
		}
		static var foo = {
				
			// addPlugin({
			// 	id: '_/1',
			// 	rules: [
			// 		{ before: true, id: '_/2' },
			// 	],
			// 	transform: function transform(e) return e
			// });	
			// addPlugin({
			// 	id: '_/2',
			// 	rules: [
			// 		{ before: true, id: '_/3' },
			// 	],
			// 	transform: function transform(e) return e
			// });	
			// addPlugin({
			// 	id: '_/3',
			// 	rules: [
			// 		{ before: true, id: '_/4' },
			// 	],
			// 	transform: function transform(e) return e
			// });	
			// addPlugin({
			// 	id: '_/4',
			// 	rules: [
			// 		// { before: true, id: 'tink_lang/one' },
			// 	],
			// 	transform: function transform(e) return e
			// });	
			
			// orderPlugins();
			// null;
		}	
		static function merge(c1:CanonicalRule, c2:CanonicalRule)
			return
				if (c1 == null) c2;
				else if (c2 == null) c1;
				else {
					if (c1.first.toString() != c2.first.toString()) 
						throw 'Conflicting rules for ${c1.first.lib+"/"+c1.first.name} and ${c2.first.lib+"/"+c2.first.name}';
					{
						first: c1.first,
						then: c1.then,
						separate: c1.separate || c2.separate
					}
				}
		
		static function canonical(p:Plugin, rule:PluginRule):CanonicalRule {
			return
				if (rule.before) {
					first: p.id,
					then: rule.id,
					separate: rule.separate == true
				}
				else {
					first: rule.id,
					then: p.id,
					separate: rule.separate == true					
				}
		}
		
		//TODO: it seems a little monolithic to yank all plugins here
		static public var PLUGINS = [
			FuncOptions.process,
			Dispatch.members,
			Init.process,
			Forward.process,
			PropBuilder.process,
			syntax(Pipelining.shortBind),
			
			simpleSugar(function (e) return switch e {
				case macro @in($delta) $handler:
					return ECheckType(
						(macro @:pos(e.pos) haxe.Timer.delay($handler, Std.int($delta * 1000)).stop),
						macro : tink.core.types.Callback.CallbackLink
					).at(e.pos);
				default: e;				
			}),
			simpleSugar(LoopSugar.comprehension),
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
			simpleSugar(Pipelining.transform, true),
			simpleSugar(DevTools.log, true),
			simpleSugar(DevTools.measure),
			simpleSugar(DevTools.explain),
			PartialImpl.process,
			simpleSugar(LoopSugar.transformLoop),
		];	
	#end
}