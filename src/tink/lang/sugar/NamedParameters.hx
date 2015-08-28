package tink.lang.sugar;

import haxe.macro.Expr;

using tink.MacroApi;

class NamedParameters {
  static function callWithFields(callee:Expr, fields:Array<{ field:String, expr:Expr }>, pos:Position) {
    var fields = [for (f in fields) f.field => f.expr],
        argList = [],
        type = callee.typeof().sure().reduce();
    return
      switch type {
        case TFun(args, _):
          if (args[0].name == '')
            callee.reject('argument names are unknown for ${type.toComplex().toString()}');
            
          for (arg in args)
            switch fields[arg.name] {
              case null:
              case v:
                argList.push(v);
                fields.remove(arg.name);
            }
            
          macro @:pos(pos) $callee($a{argList});
            
        default:
          callee.reject('not a function');
      }
  }
  
  static public function apply(e:Expr)
    return 
      switch e {
        case macro $callee(@with $obj):
          switch obj.expr {
            case EObjectDecl(fields):
              callWithFields.bind(callee, fields, e.pos).bounce(e.pos);
            default:
              e.reject('should be an object literal');
          }
        default: e;
      }
  
}