package tink.lang.sugar;

import haxe.macro.Expr;
import tink.macro.*;

using tink.MacroApi;

class DirectInitialization {
  static public function process(ctx) 
    new DirectInitialization(ctx).processMembers();
  
  var ctx:ClassBuilder;
  function new(ctx) 
    this.ctx = ctx;
  
  function getType(t:Null<ComplexType>, inferFrom:Expr) 
    return
      if (t == null) 
        inferFrom.typeof().sure().toComplex();
      else 
        t;
        
  function isConst(e:Expr)
    return switch e.expr {
      case EConst(CInt(_) | CString(_) | CFloat(_) | CIdent('true' | 'false' | 'null')): true;
      default: false;
    }
    
  function processMembers() 
    for (member in ctx) {
      if (!member.isStatic)
        switch (member.kind) {
          case FVar(_, e) | FProp(_, _, _, e) if (e == null || isConst(e)):
            if (e != null) member.addMeta(':isVar');
          case FVar(t, e):
            member.kind = FVar(t = getType(t, e), null);
            DirectInitialization.member(ctx, member, t, e);
          case FProp(get, set, t, e):
            member.kind = FProp(get, set, t = getType(t, e), null);
            DirectInitialization.member(ctx, member, t, e);          
          default:
        }
    }
    
  static public function member(ctx:ClassBuilder, member:Member, t:ComplexType, e:Expr) 
    if (ctx.target.isInterface) 
      PartialImplementation.setDefault(member, ECheckType(e, t).at(e.pos));
    else 
      field(ctx.getConstructor(), member.name, t, e);
  
  //TODO: the naming here is quite horrible
  static public function field(ctor:Constructor, name, t:ComplexType, e:Expr) {
    var init = null,
      def = null;
    ctor.init(
      name, 
      e.pos,  
      switch e {
        case macro _: Arg(t);
        case macro ($def): 
          def.pos.warning('Specifying default per `(<default>)` is deprecated. Please use `@byDefault <default>` instead.');
          OptArg(def, t);
        case macro @byDefault $def: OptArg(def, t);
        default: Value(e);
      },
      { bypass : true }
    );              
  }
}