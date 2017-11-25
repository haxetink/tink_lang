package tink.lang.sugar;

import haxe.macro.Expr;
import tink.macro.*;

using tink.MacroApi;

class PropertyNotation {
  static public inline var PROP = ':prop';
  static public inline var READ = ':read';
  static public inline var CALC = ':calc';
  static public inline var LAZY = ':lazy';
  
  static var aliases = [
    ':property' => PROP,
    ':readonly' => READ,
    ':calculated' => CALC,
    ':computed' => CALC,
    ':comp' => CALC,
  ];
    
  static public function apply(ctx:ClassBuilder) 
    new PropertyNotation(ctx).processMembers();
  
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
          
          switch (member : Field).meta {
            case null:
            case tags:
              for (m in tags)
                if (aliases.exists(m.name))
                  m.name = aliases[m.name];
          }
          switch member.extractMeta(LAZY) {
            case Success(tag):
              if (e == null)
                member.pos.error('no expression given');
              if (t == null)
                t = switch e.typeof() {
                  case Success(t): t.toComplex();
                  case Failure(_): e.pos.makeBlankType();
                }
                
              var lazyField = 'lazy_' + member.name;
              add(({
                pos: member.pos,
                name: lazyField,
                kind: FVar(macro : tink.core.Lazy<$t>, macro @:pos(e.pos) tink.core.Lazy.ofFunc(function () return $e)),
                meta: [{ name: ':noCompletion', params: [], pos: member.pos }]
              }:Field), true);
              
              e = macro @:pos(e.pos) $i{lazyField}.get();
              member.addMeta(CALC);
            default:
          }
          switch member.extractMeta(CALC) {
            case Success(tag):
              if (e == null)
                member.pos.error('no expression given');
              if (t == null)
                t = e.pos.makeBlankType();
              member.kind = FProp('get', 'never', t, null);
              member.publish();
              add(Member.getter(name, e, t));
              continue;
            default: 
          }
          
          switch member.extractMeta(READ) {
            case Success(tag):
              switch member.extractMeta(PROP) {
                case Success(tag): 
                  tag.pos.error('Cannot have both $PROP and $READ');
                default:
              }
              var get = 
                switch (tag.params.length) {
                  case 0, 1: 
                    [tag.params[0], '_'.resolve(tag.pos)];
                  default: 
                    tag.pos.error('too many arguments');
                }
              member.addMeta(PROP, tag.pos, get);
            default:
          }
          switch member.extractMeta(PROP) {
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