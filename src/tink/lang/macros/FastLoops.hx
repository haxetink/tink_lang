package tink.lang.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

using tink.MacroApi;

class FastLoops {
	static var patched = false;
	static function processRule(init:Expr, hasNext:Expr, next:Expr):CustomIter {
		var init = 
			switch (init.expr) {
				case EBlock(exprs):
					exprs;
				default:
					init.reject('must be a block');
			}
		return {
			init: init,
			hasNext: hasNext,
			next: next
		};
	}	
	static function addRules(typeName:String, fields:ComplexType) {
		var fields = 
			switch (fields) {
				case TAnonymous(fields): 
					var ret = new Map();
					for (f in fields)
						ret.set(f.name, f);
					ret;
				default: throw 'should be anon';
			}
		switch (Context.getType(typeName).reduce()) {
			case TAbstract(_, _):
			default:
				for (f in Context.getType(typeName).reduce().getFields(false).sure()) 
					if (fields.exists(f.name)) {
						if (fields.get(f.name).meta != null)
							for (m in fields.get(f.name).meta) {
								if (f.meta.has(m.name))
									f.meta.remove(m.name);
								f.meta.add(m.name, m.params, m.pos);
							}
						fields.remove(f.name);
					}
					
				for (f in fields)
					f.pos.error(typeName + ' has no field ' + f.name);
		}
	}
	
	static function nativeRules() {
		
		if (Context.defined('php')) {
			addRules('Array', 
				macro: {
					@:tink_for({ var i = 0, l = this.length, a = php.Lib.toPhpArray(this); }, i < l, a[i++])
					function iterator();
				}
			);
			for (h in 'haxe.ds.IntMap,haxe.ds.StringMap'.split(','))
				addRules(h, 
					macro: {
						@:tink_for({ 
							var i = 0, a, l;
							{
								a = untyped __call__('array_values', this.h);
								l = untyped __call__('count', a);								
							}
						}, i < l, a[i++])
						function iterator();
						@:tink_for({ 
							var i = 0, a, l;
							{
								a = untyped __call__('array_keys', this.h);
								l = untyped __call__('count', a);
							}
						}, i < l, a[i++])
						function keys();
					}
				);
		}
		else if (Context.defined('neko')) {
			var hashes = [
				{ t: 'haxe.ds.StringMap', key: macro neko.NativeString.toString(a[i++]) },
				{ t: 'haxe.ds.IntMap', key: macro a[i++] },
			];
			for (h in hashes) {
				var key = h.key;
				addRules(h.t,
					macro : { 
						@:tink_for(
							{
								var h = this.h,
									i = 0, c, a;
								{
									c = untyped __dollar__hcount(h);
									a = untyped __dollar__amake(c);
									untyped __dollar__hiter(h, function (k, _) a[i++] = k);
									i = 0;									
								}
							},
							i < c,
							$key
						) 
						function keys();
						@:tink_for(
							{
								var h = this.h,
									i = 0, c, a;
								{
									c = untyped __dollar__hcount(h);
									a = untyped __dollar__amake(c);
									untyped __dollar__hiter(h, function (_, v) a[i++] = v);
									i = 0;									
								}
							},
							i < c,
							a[i++]
						)
						function iterator();					
					}
				);
			}
			addRules('Array',
				macro: {
					@:tink_for( { var i = 0, l = this.length, a = neko.NativeArray.ofArrayRef(this); }, i < l, a[i++])
					function iterator();
				}
			);
		}
		else {
			addRules('Array',
				macro: {
					@:tink_for( { var i = 0, l = this.length; }, i < l, this[i++])
					function iterator();
				}
			);
		}
		addRules('List', 
			macro : {
				@:tink_for( { var h = this.h, x; }, h != null, { x = h[0]; h = h[1]; x; } ) function iterator();
			}
		);		
	}
	static function buildFastLoop(e:Expr, f:CustomIter) {
		var vars:Dynamic<String> = { };
		function add(name:String) {
			var n = LoopSugar.temp(name);
			Reflect.setField(vars, name, n);
			return n;
		}
		var tVar = add('this');
		for (e in f.init) {
			switch (e.expr) {
				case EVars(vars):
					for (v in vars) 
						add(v.name);
				default:
			}
		}
		var init = [tVar.define(e)];
		
		for (e in f.init) 
			init.push(e.finalize(vars, true).withPrivateAccess());
		
		return {
			init: init,
			hasNext: f.hasNext.finalize(vars, true),
			next: f.next.finalize(vars, true)
		}
	}
	
	static public function iter(e:Expr) {
		var fast = fastIter(e);
		return
			if (fast == null) null;
			else buildFastLoop(fast.target, fast.iter);
	}
	static var platforms = 'flash8,js,php,neko,flash,cpp,java,cs'.split(',');
	static function getPlatform() {
		for (p in platforms)
			if (Context.defined(p)) return p;
		return null;
	}
	static var lastPlatform = null;
	
	static function repatchIfNeeded() {
		var nuPlatform = getPlatform();
		return false;
		if (nuPlatform != lastPlatform) {
			lastPlatform = nuPlatform;
			nativeRules();
		} 
		return true;
	}
	static var MAPS = [
		'String' => 'haxe.ds.StringMap',
		'Int' => 'haxe.ds.IntMap'
	];
	static function fastIter(e:Expr) {
		if (!patched) {
			Context.onMacroContextReused(repatchIfNeeded);
			nativeRules();
			patched = true;
		}
		
		var any = e.pos.makeBlankType();
		if (!e.is(macro : Iterator<$any>)) {
			var iter = (macro $e.iterator()).finalize(e.pos);
			if (iter.typeof().isSuccess())
				return fastIter(iter);			
		}
		
		switch e {
			case macro $owner.$fieldName($a{_}):
				var oType = owner.typeof().sure().reduce();
				if (oType.getID() == 'Map') {
					switch oType {
						case TAbstract(_, [k, _]):
							var impl = MAPS.get(k.getID());
							if (impl != null) {
								oType = Context.getType(impl);
								owner = ECheckType(owner, impl.asComplexType([TPType(owner.pos.makeBlankType())])).at();
							}
						default:
					}
				}
				switch oType.getFields(false) {
					case Success(fields):
						for (field in fields) 
							if (field.name == fieldName) {
								var m = field.meta.get().getValues(':tink_for');							
								return
									switch (m.length) {
										case 0: null;
										case 1: 
											var m = m[0];
											if (m.length != 3)
												field.pos.error('@:tink_for must have 3 arguments exactly');
											{
												target: owner,
												iter: processRule(m[0], m[1], m[2])
											}
										default: field.pos.error('can only declare one @:tink_for');
									}								
							}
						
					case Failure(_): 
				}
			default: 
		}
		
		return null;
	}	
}
