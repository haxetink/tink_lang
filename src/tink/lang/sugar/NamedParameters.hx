package tink.lang.sugar;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using tink.MacroApi;

private typedef Signature = Array<{ name : String, opt : Bool, t : Type }>;
class NamedParameters {
  
  static function construct(args:Signature, fields:Map<String, Expr>, ?transform:Expr->String->Expr, pos:Position):Array<Expr> {
    if (transform == null)
      transform = function (e, _) return e;
    var ret = [];
    for (arg in args)
      switch fields[arg.name] {
        case null:
          if (!arg.opt)
            pos.error('missing argument ' + arg.name);
        case v:
          ret.push(transform(v, arg.name));
          fields.remove(arg.name);
      }    
      
    return ret;
  }
  
  static function getSignature(type:Type, pos:Position) 
    return
      switch type.reduce() {
        case TFun(args, _):
          if (args[0].name == '')
            pos.error('argument names are unknown for ${type.toComplex().toString()}');
          args;
        default:
          pos.error('not a function');
      }

  static function withFields(signature:Signature, fields:Array<{ field:String, expr:Expr }>, pos:Position, exec:Array<Expr>->Expr, ?transform) {
    var fields = [for (f in fields) f.field => f.expr];
    var ret =
      construct(
        signature,
        fields, 
        transform,
        pos
      );
            
    var left = [for (f in fields.keys()) f];
    if (left.length > 0)
      pos.error('extra fields ${left.join(", ")}');
    return exec(ret);
  }  

  static function withObject(signature:Signature, obj:Expr, exec:Array<Expr>->Expr, ?transform) {
    
    var tmp = MacroApi.tempName();
    
    var fields = [for (f in obj.typeof().sure().getFields(false).sure())
      if (Lambda.exists(signature, function (arg) return arg.name == f.name)) 
        f.name => [tmp, f.name].drill(obj.pos)
    ];
    
    return 
      macro @:pos(obj.pos) {
        var $tmp = $obj;
        ${exec(construct(signature, fields, transform, obj.pos))};
      }
  }
      
  static function callWithFields(callee:Expr, fields:Array<{ field:String, expr:Expr }>, pos:Position)
    return 
      withFields(
        getSignature(callee.typeof().sure(), callee.pos), 
        fields, 
        pos,
        function (args)
          return macro @:pos(pos) $callee($a{args})
      );
  
  static function callWithObject(callee:Expr, obj:Expr) {
    var signature = getSignature(callee.typeof().sure(), callee.pos);
    var tmp = MacroApi.tempName();
    var fields = [for (f in obj.typeof().sure().getFields(false).sure())
      if (Lambda.exists(signature, function (arg) return arg.name == f.name)) 
        f.name => [tmp, f.name].drill(obj.pos)
    ];
    
    return macro @:pos(obj.pos) {
      var $tmp = $obj;
      $callee($a{construct(signature, fields, obj.pos)});
    }
  }
  
  static public function apply(e:Expr)
    return 
      switch e {
        case macro $callee(@with $obj):
          switch obj.expr {
            case EObjectDecl(fields):
              callWithFields.bind(callee, fields, obj.pos).bounce(e.pos);
            default:
              callWithObject.bind(callee, obj).bounce(e.pos);
          }
          
        case { expr: ENew(path, [macro @with $obj]) } :
          //path.toString();
          (function () {
            var arr = path.pack.concat([path.name]);
            if (path.sub != null)
              arr.push(path.sub);
              
            var name = arr.join('.');
            return
              switch Context.getType(name).reduce() {
                case TInst(_.get() => cls, _): 
                  var ctor = null;
                  while (cls != null) {
                    if (cls.constructor == null) {
                      if (cls.superClass != null) 
                        cls = cls.superClass.t.get();  
                      else
                        break;
                    }
                    else {
                      ctor = cls.constructor;
                      break;
                    }
                  }
                  if (ctor == null)
                    e.reject('$name has no constructor');
                    
                  var signature = getSignature(ctor.get().type, e.pos),
                      tmp = MacroApi.tempName();
                  switch obj.expr {
                    case EObjectDecl(fields):
                      //var set = withFields(signature, fields, obj.pos, function (e, name) return [tmp, name].drill(e.pos).assign(e, e.pos));
                      withFields(signature, fields, obj.pos, function (args) return ENew(path, args).at(e.pos));
                    default:
                      withObject(signature, obj, function (args) return ENew(path, args).at(e.pos));
                  }
                case TAbstract(_, _):
                  throw 'not implemented';
                default:
                  e.reject('$name cannot be instantiated');
              }
          }).bounce(e.pos);
        default: e;
      }
  
}