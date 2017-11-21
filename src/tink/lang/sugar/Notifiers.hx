package tink.lang.sugar;

import haxe.macro.Expr;
import tink.macro.*;
import tink.core.*;

using tink.MacroApi;

class Notifiers {
  static function mk(s:String, t)
    return s.asComplexType([TPType(t)]);

  static function make(type:String) {
    var Type = type.charAt(0).toUpperCase() + type.substr(1);
    return new Pair(':$type', {
      published: function (t) return mk('tink.core.$Type', t),
      internal: function (t) return mk('tink.core.$Type.${Type}Trigger', t),
      init: function (pos, t) return ENew('tink.core.$Type.${Type}Trigger'.asTypePath([TPType(t)]), []).at(pos),
      publish: function (e:Expr) return e.field('as$Type', e.pos).call(e.pos)
    });
  }
  static function outcome(t)
    return macro : tink.core.Outcome<$t, tink.core.Error>;

  static var types = [
    make('signal'),
    make('future'),
    new Pair(':promise', {
      published: function (t) return mk('tink.core.Promise', t),
      internal: function (t) return mk('tink.core.Future.FutureTrigger', outcome(t)),
      init: function (pos, t) return ENew('tink.core.Future.FutureTrigger'.asTypePath([TPType(outcome(t))]), []).at(pos),
      publish: function (e:Expr) return e 
    })
  ];
  
  static public function apply(ctx:ClassBuilder) {
    for (type in types) {
      var make = type.b;
      for (member in ctx)   
        switch (member.extractMeta(type.a)) {
          case Success(tag):
            switch (member.kind) {
              case FVar(t, e):
                if (t == null)
                  t = if (e == null) 
                      macro : tink.core.Noise;
                    else 
                      e.pos.makeBlankType();
                if (e == null) {  
                  var own = '_' + member.name;
                  ctx.addMember( {
                    name: own,
                    kind: FVar(make.internal(t), make.init(tag.pos, t)),
                    pos: tag.pos
                  }, true).isPublic = false;  
                  e = make.publish(own.resolve(tag.pos));
                }
                member.kind = FVar(make.published(t), e);
                member.addMeta(':read');
              default:
                member.pos.error('can only use @${type.a} on variables');
            }
          default:
        }
    }
  }  
}