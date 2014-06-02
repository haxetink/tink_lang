package tink.lang.macros;

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.ds.Option;

using tink.MacroApi;

private abstract Fieldish({ set: String->Bool->Expr->Void, get: Void->Metadata, pos:Position, name:String }) {
	
	public var pos(get, never):Position;
	function get_pos() return this.pos;
	
	public var name(get, never):String;
	function get_name() return this.name;
	
	function new(pos, name, get, set) this = { pos: pos, get: get, set: set, name: name };
	
	public function setMeta(name, single, expr)
		this.set(name, single, expr);
		
	public function getMeta()
		return this.get();
	
	@:from static function ofMember(m:Member) 
		return new Fieldish(
			m.pos, 
			m.name,
			{
				var f:Field = m;
				function () return f.meta;
			}, 
			function (name, single, expr:Expr) {
				if (single)
					while (m.extractMeta(name).isSuccess()) {}
				m.addMeta(name, expr.pos, [expr]);
			}
		);
		
	@:from static function ofClassField(f:ClassField) 
		return new Fieldish(
			f.pos, 
			f.name,
			f.meta.get, 
			function (name, single, expr:Expr) {
				if (single && f.meta.has(name))
					f.meta.remove(name);
				f.meta.add(name, [expr], expr.pos);
			}
		);
	
}

class PartialImpl {
	
	static inline var DEFAULT = ':defaultImplementation';
	static inline var REQUIRES = ':defaultRequires';
	
	static function getDefault(f:Fieldish, paramMap) 
		return
			switch f.getMeta().getValues(DEFAULT) {
				case []: None;
				case [[ret]]: Some(ret.substParams(paramMap));
				default: f.pos.error('multiple defaults defined');
			}
	
	static public function addDependency(f:Fieldish, fields:Array<Member>) {
		var t = TAnonymous(fields);
		f.setMeta(REQUIRES, false, macro cast(null, $t));//TODO: check this causes no problems with compiler cache
	}
	
	static function getDependencies(f:Fieldish, paramMap):Array<Member> {
		var ret = [];
		
		for (m in f.getMeta())
			if (m.name == REQUIRES) 
				switch m.params {
					case [e]:
						e = e.substParams(paramMap);
						switch e {
							case macro cast(null, $t):
								switch t {
									case TAnonymous(fields):
										ret = ret.concat(fields);
									default:
										e.reject('Bad @$REQUIRES clause');
								}
							default:
								e.reject('Bad @$REQUIRES clause');
						}
					default:
						m.pos.error('Bad @$REQUIRES clause');
				}
		
		// for (m in ret.copy())
		// 	ret = ret.concat(getDependencies(m, paramMap));
		
		return ret;
	}
	
	static public function setDefault(f:Fieldish, expr:Expr) 
		f.setMeta(DEFAULT, true, expr);
	
	static public function process(ctx:ClassBuilder) {
		if (ctx.target.isInterface) {
			var toRemove = [];
			for (m in ctx) 
				switch m.extractMeta(':usedOnlyBy') {
					case Success(tag):
						for (p in tag.params)
							addDependency(ctx.memberByName(p.getIdent().sure(), p.pos).sure(), [m]);
						toRemove.push(m);
					default:
						switch m.kind {
							case FFun(f):
								if (f.expr != null) {
									m.addMeta(DEFAULT, f.expr.pos, [Reflect.copy(f).asExpr()]);
									f.expr = null;
								}
							default:
						}
				}			
			for (m in toRemove)
				ctx.removeMember(m);
		}
		else {
			var dependencies = [];
			for (i in ctx.target.interfaces)
				for (f in TInst(i.t, i.params).getFields(true).sure()) {
					var index = 0,
						paramMap = new Map();
						
					for (p in i.t.get().params)
						paramMap.set(p.name, i.params[index++].toComplex());					
						
					function addDependencies()
						dependencies.push({
							params: paramMap,
							fields: getDependencies(f, paramMap)
						});
					
					if (!ctx.hasMember(f.name)) {
						switch (f.kind) {
							case FVar(read, write):
								ctx.addMember({
									name: f.name,
									access: f.isPublic ? [APublic] : [APrivate],
									kind: FProp(read.accessToName(), write.accessToName(true), f.type.toComplex()),
									pos: f.pos
								});
								
								switch getDefault(f, paramMap) {
									case Some(d):
										
										addDependencies();
										
										switch (d.expr) {
											case ECheckType(e, t):
												Init.field(ctx.getConstructor(), f.name, t, e);
											default:
												Init.field(ctx.getConstructor(), f.name, f.type.toComplex(), d);//for people who specify this manually
										}
									case None:
								}
								
							case FMethod(_):
								switch getDefault(f, paramMap) {
									
									case Some(d):
										
										addDependencies();
										
										switch (d.expr) {
											case EFunction(_, impl):
												ctx.addMember({
													name: f.name,
													access: f.isPublic ? [APublic] : [APrivate],
													kind: FFun(impl),
													pos: f.pos
												});									
											default:
												d.reject();
										}									
									case None:
								}
						}
					}
				}
			
			while (dependencies.length > 0) {
				var last = dependencies;
				dependencies = [];
				for (dep in last) 
					for (f in dep.fields)
						if (!ctx.hasMember(f.name)) {
							
							ctx.addMember(Reflect.copy(f));
							
							dependencies.push({
								fields: getDependencies(f, dep.params),
								params: dep.params
							});
							
							switch f.getVar() {
								case Success({ type: type }):
									switch getDefault(f, dep.params) {
										case Some(d):
											switch (d.expr) {
												case ECheckType(e, t):
													Init.field(ctx.getConstructor(), f.name, t, e);
												default:
													Init.field(ctx.getConstructor(), f.name, type, d);
											}
										case None:
									}
								default:
							}
						}
			}
			
		}
	}	
}