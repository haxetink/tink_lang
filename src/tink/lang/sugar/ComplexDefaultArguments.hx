package tink.lang.sugar;

import haxe.macro.Expr;
import tink.macro.*;
using tink.CoreApi;
using tink.MacroApi;

class ComplexDefaultArguments {
  static public function members(c:ClassBuilder) {
    for (m in c)
      switch m.getFunction() {
        case Success(f): options(f, m.pos);
        default:
      }
    if (c.hasConstructor())
      c.getConstructor().onGenerate(function (f) options(f, f.expr.pos));
  }
  
  static function options(f:Function, pos:Position) {
    f.expr = 
      f.expr.transform(
        function (e) return switch e.expr {
          case EFunction(_, f):
            options(f, e.pos);
            e;
          default: e;
        }
      );
      
    var body =
      switch f.expr {
				case null: 
					return;
        case { expr: EBlock(body) }: body;
        default:
          var body = [f.expr];
          f.expr = body.toMBlock();
          body;
      }
    
    function prepend(e) 
      body.unshift(e);
    
    var args = f.args.copy();
    args.reverse();
    for (arg in args)
      if (arg.value != null) 
        switch arg.value.expr {
          case EObjectDecl(parts):
            var opt = true,
                fields = new Array<Field>(),
                direct = arg.name == '_';
              
            if (direct)  
              arg.name = MacroApi.tempName();
              
            function add(pos, name, init:Expr) {
              if (init.isWildcard())
                init = null;
                
              if (init == null) 
                opt = false;
                
              if (direct) 
                if (init == null)
                  prepend(macro @:pos(pos) var $name = $i{arg.name}.$name);
                else
                  prepend(macro @:pos(pos) var $name = if ($i{arg.name}.$name == null) $init else $i{arg.name}.$name);
              else
                if (init == null) 
                  opt = false;
                else 
                  prepend(macro @:pos(pos) if ($i{arg.name}.$name == null) $i{arg.name}.$name = ${init});
                
              var type = 
                switch init {
                  case null: 
                    pos.makeBlankType();
                  case macro ($_ : $t):
                    t;
                  default:
                    switch init.typeof() {
                      case Success(type): type.toComplex({ direct: true });
                      default: pos.makeBlankType();
                    }
                    //TODO: this code should do the same as the switch above but results in "macro returned an invalid result"
                    // init.typeof().map(Types.toComplex.bind(_, { direct: true })).orUse(pos.makeBlankType());
                }
                  
                    
              type = macro : Null<$type>;
              fields.push({
                name: name,
                pos: pos,
                kind: FVar(type),
                meta: if (init == null) null else [{ name : ':optional', pos: pos, params: [] }]
              });
            }
            parts.reverse();
            for (f in parts)
              add(f.expr.pos, f.field, f.expr);
              
            if (opt) {
              prepend(macro if ($i{arg.name} == null) $i{arg.name} = {});
              arg.opt = true;
            }
            
            arg.type = TAnonymous(fields); //TODO: we could trick the typer into looking over the body
            arg.value = macro null;
          default:
            if (!(macro function (__ = ${arg.value}) {}).typeof().isSuccess()) {
              arg.type = arg.value.pos.makeBlankType();
              prepend(macro if ($i{arg.name} == null) $i{arg.name} = ${arg.value});
              arg.value = macro null;
            }
        }
  }
}