package tink.lang.sugar;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.*;

using tink.MacroApi;
using StringTools;
using Lambda;

typedef ClassFieldFilter = ClassField->Bool;
typedef ForwardRules = { call:Null<Expr>, get:Null<Expr>, set:Null<Expr> };

class Forwarding {
  static inline var TAG = ":forward";
  static public function apply(ctx:ClassBuilder)
    new Forwarding(ctx).processMembers();

  var ctx:ClassBuilder;
  function new(ctx)
    this.ctx = ctx;

  function processMembers()
    for (member in ctx)
      switch (member.extractMeta(TAG)) {
        case Success(tag):
          switch (member.kind) {
            case FVar(t, _):
              forwardTo(member, t, tag.pos, tag.params);
            case FProp(_, _, t, _):
              forwardTo(member, t, tag.pos, tag.params);
            case FFun(f):
              forwardWithFunction(f, tag.pos, tag.params, member.isBound);
              ctx.removeMember(member);
          }
        default:
      }

  inline function has(name)
    return ctx.hasMember(name);

  inline function add(member, ?front)
    return ctx.addMember(member, front);

  function forwardWithFunction(f:Function, pos:Position, params:Array<Expr>, isBound:Bool) {
    var rules = {
      call: null,
      get: null,
      set: null
    };
    switch (f.expr.expr) {
      case EObjectDecl(fields):
        for (field in fields)
          switch (field.field) {
            case 'get':  rules.get = field.expr;
            case 'set':  rules.set = field.expr;
            case 'call': rules.call = field.expr;
          }
      default: f.expr.reject();
    }

    var filter = makeFilter(params);
    for (arg in f.args)
      forwardWith(arg.name, rules, arg.type, pos, filter, isBound);
  }
  function forwardWith(id:String, rules:ForwardRules, t:ComplexType, pos:Position, filter:ClassFieldFilter, ?isBound:Bool) {
    var fields = t.toType(pos).sure().getFields().sure();
    for (field in fields)
      if (field.isPublic && filter(field) && !has(field.name)) {
        switch (field.kind) {
          case FVar(read, write):
            forwardVarWith(id, rules.get, rules.set, isAccessible(read, true), isAccessible(write, false), field.name, field.type.toComplex(), pos, isBound);
          case FMethod(_):
            if (rules.call != null) {
              switch (Context.follow(field.type)) {
                case TFun(args, ret):
                  forwardFunctionWith(id, rules.call, pos, field.name, args, ret, field.params, isBound);
                default:
                  pos.error('wtf?');
              }
            }
        }
      }
  }
  function forwardToType(t:Type, included:ClassFieldFilter, target:Expr, pos:Position, bound:Null<Bool>) {
    for (field in t.getFields().sure())
      if (field.isPublic && included(field) && !has(field.name)) {
        switch (field.kind) {
          case FVar(read, write):
            forwardVarTo(target, field.name, field.type.toComplex(), read, write, bound);
          case FMethod(_):
            switch (Context.follow(field.type)) {
              case TFun(args, ret):
                forwardFunctionTo(target, field.name, args, ret, field.params, bound);
              default:
                pos.error('wtf?');
            }
        }
      }
  }
  function forwardTo(to:Member, t:ComplexType, pos:Position, params:Array<Expr>) {
    var t = t.toType(pos).sure().reduce(),
      target = ['this', to.name].drill(pos),
      included = makeFilter(params);

    forwardToType(t, included, target, pos, to.isBound);
  }
  function forwardFunctionWith(id:String, callExpr:Expr, pos:Position, name:String, args:Array<{ name : String, opt : Bool, t : Type }>, ret : Type, params: Array<{ name : String, t : Type }>, isBound:Bool) {
    //TODO: there's a lot of duplication with forwardFunctionTo here
    var methodArgs = [],
      callArgs = [];

    for (arg in args) {
      callArgs.push(arg.name.resolve(pos));
      methodArgs.push( { name : arg.name, opt : arg.opt, type : arg.t.toComplex(), value : null } );
    }
    var methodParams = [].toBlock().func().params;//TODO: be less lazy
    for (param in params)
      methodParams.push( { name : param.name, constraints: [] } );

    var call = callExpr.substitute( {
      "$args": callArgs.toArray(),
      "$id": id.toExpr(),
      "$name": name.toExpr()
    });
    add(Member.method(name, call.func(methodArgs, methodParams))).isBound = isBound;
  }
  function forwardVarWith(id:String, eGet:Null<Expr>, eSet:Null<Expr>, read:Bool, write:Bool, name, t, pos, isBound:Bool) {
    read = read && eGet != null;
    write = write && eSet != null;

    if (!(read || write)) return;//I hate guard clauses, but I feel very lazy now

    add(Member.prop(name, t, pos, !read, !write));
    var vars = {
      "$name": name.toExpr(),
      "$id": id.toExpr()
    }
    if (read)
      add(Member.getter(name, pos, eGet.substitute(vars), t)).isBound = isBound;
    if (write)
      add(Member.setter(name, pos, eSet.substitute(vars), t)).isBound = isBound;
  }
  function forwardFunctionTo(target:Expr, name:String, args:Array<{ name : String, opt : Bool, t : Type }>, ret : Type, params: Array<{ name : String, t : Type }>, bound:Null<Bool>) {
    var methodArgs = [],
      callArgs = [],
      pos = target.pos;

    for (arg in args) {
      callArgs.push(arg.name.resolve(target.pos));
      methodArgs.push( { name : arg.name, opt : arg.opt, type : arg.t.toComplex(), value : null } );
    }
    var methodParams = [].toBlock().func().params;//TODO: be less lazy
    for (param in params)
      methodParams.push( { name : param.name, constraints: [] } );
    add(Member.method(name, target.field(name, pos).call(callArgs, pos).func(methodArgs, ret.toComplex(), methodParams))).isBound = bound;
  }
  function isAccessible(a:VarAccess, read:Bool) {
    return switch(a) {
      case AccNormal, AccCall: true;
      case AccInline: read;
      default: false;
    }
  }
  function forwardVarTo(target:Expr, name:String, t:ComplexType, read:VarAccess, write:VarAccess, bound:Null<Bool>) {
    var pos = target.pos;
    if (!isAccessible(read, true))
      pos.error('cannot forward to non-readable field ' + name + ' of ' + t);
    add(Member.prop(name, t, pos, false, !isAccessible(write, false))).isBound = bound;
    if (!has('get_$name'))
      add(Member.getter(name, pos, target.field(name, pos), t)).isBound = bound;
    if (!has('set_$name'))
      if (isAccessible(write, false))
        add(Member.setter(name, pos, target.field(name, pos).assign('param'.resolve(pos), pos), t));
  }
  static function and(a, b) {
    return function (c) return a(c) && b(c);
  }
  static function or(a, b) {
    return function (c) return a(c) || b(c);
  }
  static function not(a) {
    return function (c) return !a(c);
  }
  static function one(filters:Iterable<ClassFieldFilter>) {
    return function (c) {
      for (filter in filters)
        if (filter(c))
          return true;
      return false;
    }
  }
  static function makeFilter(exprs:Array<Expr>) {
    return
      if (exprs.length == 0)
        function (_) return true;
      else
        one(exprs.map(makeFieldFilter));
  }
  static function matchRegEx(r:String, opt:String):ClassFieldFilter {
    var r = new EReg(r, opt);
    return function (field) return r.match(field.name);
  }
  static public function makeFieldFilter(e:Expr):ClassFieldFilter {
    return
      switch (e.expr) {
        case EArrayDecl(exprs): one(exprs.map(makeFieldFilter));
        case EConst(c):
          switch (c) {
            case CIdent(s):
              if (s.startsWith('$'))
                switch (s.substr(1)) {
                  case 'var': function (field:ClassField) return field.isVar();
                  case 'function': function (field:ClassField) return !field.isVar();
                  default: e.reject('invalid option');
                }
              else
                function (field) return field.name == s;
            case CString(s):
              matchRegEx('^' + StringTools.replace(s, '*', '.*') + '$', 'i');
            case CRegexp(r, opt):
              matchRegEx(r, opt);
            default: e.reject('invalid constant');
          }
        case EBinop(op, e1, e2):
          switch (op) {
            case OpAnd, OpBoolAnd: and(makeFieldFilter(e1), makeFieldFilter(e2));
            case OpOr, OpBoolOr: or(makeFieldFilter(e1), makeFieldFilter(e2));
            default: e.reject('invalid operator');
          }
        case EUnop(op, postfix, arg):
          if (postfix || op != OpNot) e.reject();
          not(makeFieldFilter(arg));
        case EParenthesis(e):
          makeFieldFilter(e);
        default: e.reject();
      }
  }
}
#end