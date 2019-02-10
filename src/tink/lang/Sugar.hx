package tink.lang;
import tink.priority.Selector;

#if macro
  import haxe.macro.Context;
  import haxe.macro.Expr;
  import tink.lang.sugar.*;
  import tink.macro.ClassBuilder;
  import tink.priority.Queue;
  
  using haxe.macro.MacroStringTools;
  using tink.MacroApi;
  using tink.CoreApi;
#end
  
  
typedef Plugin = Callback<ClassBuilder>;

class Sugar {
  
  #if macro
    
    static function shortcuts(e:Expr)
      return switch e {
        case macro @until($future) $link:
          
          shortcuts(macro @:pos(e.pos) @when($future) ($link : tink.core.Callback.CallbackLink));
          
        case macro @when($future) $handler:
          var any = e.pos.makeBlankType();
          
          function futurize(e:Expr) {
            var any = e.pos.makeBlankType();
            return macro @:pos(e.pos) ($e : tink.core.Future<$any>);
          }
          
          switch future.expr {
            case EObjectDecl([]):
              future.reject('At least on field must be defined in this notation');
            case EObjectDecl([{ field: field, expr: future }]):
              macro @:pos(e.pos) ${futurize(future)}.map(function (r) return { $field: r }).handle($handler);
            case EObjectDecl(fields):
              fields = [for (f in fields) { field: f.field, expr: futurize(f.expr ) } ];
              
              var retType = ComplexType.TAnonymous([
                for (f in fields) {
                  name: f.field,
                  pos: f.expr.pos,
                  kind: FVar(
                    (function () return switch f.expr.typeof() {
                      
                      case Success(TAbstract(_, [t])): t;
                      
                      case Failure(error):
                      
                        trace(f.expr.toString());
                        throw 'what';
                        
                      default: throw 'assert';
                    }).lazyComplex()
                  )
                }
              ]);
              
              var block = [
                (macro 
                  var tmpData:$retType = cast { }, 
                      tmpCount = $v{fields.length},
                      tmpTrigger = Future.trigger()
                ),
                macro function tmpProgress() if (--tmpCount == 0) tmpTrigger.trigger(tmpData)
              ];
              
              for (f in fields) {
                var name = f.field;
                block.push(macro 
                  ${f.expr}.handle(function (value) {
                    tmpData.$name = value;
                    tmpProgress();
                  })
                );
              }
                
              block.push(macro @:pos(e.pos) tmpTrigger.asFuture().handle($handler));
              //trace(block.toString());
              block.toBlock(e.pos);
            default:  
              macro @:pos(e.pos) ${futurize(future)}.handle($handler);
          }
          
        case macro @whenever($signal) $handler:
          var any = e.pos.makeBlankType();
          macro @:pos(e.pos) ($signal : tink.core.Signal<$any>).handle($handler);
        
        case macro @in($delta) $handler:
        
          macro @:pos(e.pos) (
            haxe.Timer.delay($handler, Std.int($delta * 1000)).stop :
            tink.core.Callback.CallbackLink
          );
          
        case macro @every($delta) $handler:
        
          macro @:pos(e.pos) (
            {
              var t = new haxe.Timer(Std.int($delta * 1000));
              t.run = $handler;
              t.stop;
            } : tink.core.Callback.CallbackLink
          );
        
        default: e;
      }
      
    static function defaultVal(e:Expr)
      return switch e { 
        case (macro $val || if ($x) $def)
          ,(macro $val | if ($x) $def):
          macro @:pos(e.pos) {
            var ___val = $val;
            (___val == $x ? $def : ___val);
          }
        default: e;
      }
      
    static function switchType(e:Expr) 
      return switch e.expr {
        case ESwitch(target, cases, def) if (cases.length > 0):
          switch cases[0].values {
            case [macro ($_: $_)]:
              if (def == null) target.reject('Type switches need default clause');
              for (c in cases) 
                c.values = 
                  switch c.values {
                    case [macro ($pattern : $t)]:
                      var pos = c.values[0].pos;
                      
                      var te = switch t {
                        case TPath({ pack: parts, name: name, params: params, sub: sub}): 
                          parts = parts.copy();
                          parts.push(name);
                          
                          if (params != null)
                            for (p in params)
                              switch p {
                                case TPType(macro : Dynamic):
                                default: pos.error('Can only use `Dynamic` type parameters in type switching');
                              }
                          if (sub != null)
                            parts.push(sub);
                            
                          parts.drill(pos);
                            
                        default: 
                          pos.error('Invalid type for switching');
                      }
                      
                      [macro @:pos(pos) (if (Std.is(_, $te)) [(_ : $t)] else []) => [$pattern]];
                    case [macro $i{ _ }]:
                      c.values;
                    default: 
                      c.values[0].reject();
                  }
              e;
            default: e;
          }
        default: e;
      }
    
    static function switchRange(e:Expr) {
      return switch e.expr {
        case ESwitch(_, cases, _):
          for (c in cases)
            c.values = [for (v in c.values) 
              fancyMatching(v)
            ];
          e;
        default: e;
      }      
    }

    
    static function fancyMatching(e:Expr)
      return
        if (e == null) null;
        else switch e {
          case macro $lh => $rh: 
            macro @:pos(e.pos) $lh => ${fancyMatching(rh)};
          case macro $lh ... $rh:
            macro @:pos(e.pos) _ >= $lh && _ < $rh  => true;
          case { expr: EConst(CString(s)) } if (MacroStringTools.isFormatExpr(e)):
            switch (s.formatString(e.pos):Expr) {
              case { expr: EConst(CString(_)) }: e;
              case v: 
                var parts = [],
                    constants = [];

                function add(b:Expr) {
                  parts.unshift(b);
                  if (b.getString().isSuccess())
                    constants.unshift(b);                  
                }

                while (true)
                  switch v {
                    case macro $a + $b:
                      v = a;
                      add(b);
                    default: break;
                  }
                add(v);

                (macro @:pos(e.pos) tink.lang.Match.fragments(_, [$a{constants}]) => [$a{parts}]);
            }
          case { expr: EConst(CRegexp(_, _)) }:
            macro @:pos(e.pos) _ != null && $e.match(_) => true;
          case { expr: EArrayDecl(_.map(fancyMatching) => v) }:
            e = v.toArray(e.pos);
            for (i in 0...v.length)
              switch v[i] {
                case macro @rest $i{name}:
                  var head = v.slice(0, i);
                  var tail = v.slice(i + 1);
                  
                  e = (macro { 
                    head: _.slice(0, $v{head.length}), 
                    rest: _.slice($v{head.length}, _.length - $v{tail.length}),
                    tail: _.slice(_.length - $v{tail.length}),
                  } => {
                    rest: $i{name},
                    head: $a{head},
                    tail: $a{tail},
                  });
                default:
              }
            e;
          default: 
            e.map(fancyMatching);
        }
    
    static function use() {
      
      function appliesTo(c:ClassBuilder)
        return c.target.meta.has(':tink');
        
      function queue<T>(queue:Queue<T>, items:Array<Pair<String, T>>, ?addFirst) {        
        var first = items.shift();
        if (first == null)
          return;
          
        if (addFirst == null)
          addFirst = queue.whenever;
        
        addFirst(first.b, first.a);
        
        var last = first.a;
        for (item in items) 
          queue.after(last, item.b, last = item.a);
      }
      
      function p<X>(a:String, b:X)
        return new Pair('tink.lang.sugar.$a', b);
      
      {
        var p = function (a, b)
          return 
            p(a, function (c:ClassBuilder) return if (appliesTo(c)) { b(c); true; } else false);
          
        queue(SyntaxHub.classLevel, [
          p('Hxx::functionBody', function (c) for (m in c) switch m.kind {
            case FFun(f = { expr: e }) if (e != null):

              while (true) switch e.expr {
                case EBlock([v]): e = v;
                default: break;
              }
              
              switch e {
                case v = { expr: EConst(CString(_)) }, macro @:markup $v:
                  f.expr = macro @:pos(f.expr.pos) return hxx($v);
                default:
              }
            default:
          }),
          p('Notifiers', Notifiers.apply),
          p('PropertyNotation', PropertyNotation.apply),
          p('DirectInitialization', DirectInitialization.process),
          p('Forwarding', Forwarding.apply),
          p('ComplexDefaultArguments::members', ComplexDefaultArguments.members),
        ], function (x, ?y, ?z) SyntaxHub.classLevel.before(SyntaxHub.exprLevel.id, x, y, z));
        
        SyntaxHub.classLevel.after(
          function (_) return true, //this is a little aggressive but I see no reason why it should happen sooner
          function (c:ClassBuilder) {
            if (c.target.isInterface && !appliesTo(c))
              return false;
            
            if (!appliesTo(c)) {
              for (i in c.target.interfaces)
                if (i.t.get().meta.has(':tink')) {
                  PartialImplementation.apply(c);
                  return true;
                }
              return false;
            }
            else {
              PartialImplementation.apply(c);
              return true;
            }
          }
        );
      }  
      
      {
        
        var p = function (a, b)
          return p(a, {
            appliesTo: appliesTo,
            apply: b
          });
        
        queue(SyntaxHub.exprLevel.inward, [
          p('Hxx::apply', function (e:Expr) return switch e {
            case { expr: EFunction(name, { ret: r, args: a, params: p, expr: { pos: pos, expr: EConst(CString(s)) } } )}:
              EFunction(name, { ret: r, args: a, params: p, expr: macro @:pos(pos) return hxx($v{s}) }).at(e.pos);
            case macro @hxx $v, macro @:markup $v: macro @:pos(v.pos) hxx($v);
            default: e;
          }),
          p('ShortLambdas::protectArrows', ShortLambdas.protectArrows),
          p('ShortLambdas::matchers', ShortLambdas.matchers),
          p('ExtendedLoops::comprehensions', ExtendedLoops.comprehensions),
          p('ExtendedLoops::transform', ExtendedLoops.apply),
        ]);
        
        queue(SyntaxHub.exprLevel.outward, [
          p('shortcuts', shortcuts),
          p('switchRange', switchRange),
          p('switchType', switchType),
          
          p('ShortLambdas::process', ShortLambdas.process),
          p('TrailingArguments', TrailingArguments.apply),
          p('NamedParameters', NamedParameters.apply),
          p('Default', defaultVal),
        ]);        
      }
        
    }
    
  #end
}
