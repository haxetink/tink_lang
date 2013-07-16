package tink.lang.macros;

import haxe.macro.Expr;
import tink.macro.*;

using tink.macro.Tools;

class PropBuilder {
	static public inline var FULL = ':prop';
	static public inline var READ = ':read';
	
	static public function process(ctx:ClassBuilder) 
		new PropBuilder(ctx).processMembers();
	
	static public function make(m:Member, t:ComplexType, getter:Expr, setter:Null<Expr>, hasField:String->Bool, addField:Member->?Bool->Member, ?e:Expr) {
		var get = 'get_' + m.name,
			set = if (setter == null) 'null' else 'set_' + m.name;
		var acc = [];
		function mk(gen:Member) {
			acc.push(gen);
			addField(gen);
			gen.isStatic = m.isStatic;
			gen.isBound = m.isBound;
			gen.addMeta(':noCompletion');
		}
		if (!hasField(get))	
			mk(Member.getter(m.name, getter, t));
		if (setter != null && !hasField(set))
			mk(Member.setter(m.name, setter, t));
		
		m.kind = FProp(get, set, t, e);
		m.publish();
		return {
			field: m,
			get: acc[0],
			set: acc[1]
		}
	}
	var ctx:ClassBuilder;
	function new(ctx) 
		this.ctx = ctx;
	
	inline function has(name)
		return ctx.hasOwnMember(name);
		
	inline function add(member, ?front)
		return ctx.addMember(member, front);
	
	
	function processMembers() {
		for (member in ctx)
			switch (member.kind) {
				case FVar(t, e):					
					var name = member.name;
					
					switch member.extractMeta(READ) {
						case Success(tag):
							switch member.extractMeta(FULL) {
								case Success(tag): 
									tag.pos.error('Cannot have both $FULL and $READ');
								default:
							}
							var get = 
								switch (tag.params.length) {
									case 0, 1: 
										[tag.params[0], '_'.resolve(tag.pos)];
									default: 
										tag.pos.error('too many arguments');
								}
							member.addMeta(FULL, tag.pos, get);
						default:
					}
					switch member.extractMeta(FULL) {
						case Success(tag):
							var getter = null,
								setter = null,
								field = ['this', name].drill(tag.pos);
							switch (tag.params.length) {
								case 0:
									member.addMeta(':isVar', tag.pos);
									getter = field;
									setter = field.assign('param'.resolve());
								case 1:
									member.addMeta(':isVar', tag.pos);
									getter = field;
									setter = field.assign(tag.params[0], tag.params[0].pos);
								case 2: 
									getter = tag.params[0];
									if (getter == null)
										getter = field;
										
									setter = tag.params[1];
									if (setter.isWildcard()) setter = null;
								default:
									tag.pos.error('too many arguments');
							}
							make(member, t, getter, setter, has, add, e);
						default:	
					}												
				default: //maybe do something here?
			}		
	}
}