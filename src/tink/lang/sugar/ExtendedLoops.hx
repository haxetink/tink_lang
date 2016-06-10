package tink.lang.sugar;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

typedef LoopHead = {
  varName:String,
  target:Expr,
  ?fallback:Expr,
}

class ExtendedLoops {
  
  static function parseTuple(e:Expr) 
    return 
      [while (e != null)
        switch e {
          case macro $a => $b:
            e = b;
            a;
          case last: 
            e = null;
            last;
        }    
      ];
  
  static function doComprehension(head:Expr, body:Expr, pos:Position, yielder:Array<Expr>->Position->Expr, init:Expr) {
    if (init == null) 
      init = macro @:pos(pos) [];
    
    function doYield(e:Expr) {
      if (yielder == null) 
        yielder = 
          switch e {
            case macro $a => $b:
              
              init = macro @:pos(pos) new Map();
              
              function (args, pos) 
                return macro @:pos(pos) __tmp.set($a{args});
              
            default:
              
              function (args, pos) 
                return macro @:pos(pos) __tmp.push($a{args});
          }
          
      return yielder(parseTuple(e), e.pos);
    }
    
    var yieldOccurred = false;
    
    body = body.transform(function (e) return switch e {
      case macro @yield $e:
        yieldOccurred = true;
        doYield(e);
      default: e;
    });
    
    if (!yieldOccurred)
      body = body.yield(doYield);
    return macro @:pos(pos) {
      var __tmp = $init;
      for ($head) $body;
      __tmp;
    }
    
  }
  
  static function hasLoop(exprs:Array<Expr>) {
    for (e in exprs)
      switch e.expr {
        case EFor(_, _): return true;
        default:
      }
      
    return false;
  }
  
  static public function comprehensions(expr:Expr) 
    return
      switch expr {
        case macro $owner.$field(for ($head) $body):
          
          doComprehension(head, body, expr.pos, function (args, pos) return macro @:pos(pos) $owner.$field($a{args}), owner);
          
        case macro [for ($head) $body]: 
          
          doComprehension(head, body, expr.pos, null, null);
          
        default: 
          
          expr;
      }
      
  
  static public function apply(e:Expr) 
    return switch e {
      case macro for ($i{_} in $_) $_: e;      
      case macro for ($head) $body:
        var init = [];
        
        function parseHead(e:Expr):LoopHead {
          
          function num(v:Expr, start, end, step, up, ?fallback):LoopHead
            return {
              varName: v.getIdent().sure(),
              fallback: fallback,
              target: {
                var method = up ? 'upto' : 'downto';
                macro @:pos(e.pos) tink.lang.Iterate.$method($step, $start, $end);
              }
            }
          
          function normal(v:Expr, target:Expr, fallback):LoopHead //TODO: "normal" is a really lousy name for this
            return {
              varName: 
                switch v {
                  case macro $i{key} => $i{val}: 
                    
                    var tmp = MacroApi.tempName();
                    
                    init.push(macro var $tmp = $target);
                    
                    target = macro tink.lang.Iterate.keys($i{tmp});
                    
                    body = macro @:pos(v.pos) {
                      var $val = tink.lang.Iterate.getKey($i{tmp}, $i{key});
                      $body;
                    }
                    
                    key;
                    
                  case macro $i{name}: name;
                  
                  default:
                    var tmp = MacroApi.tempName();
                    
                    body = macro @:pos(v.pos) switch $i{tmp} {
                      case $v: $body;
                      default: $b{[]}; //need this to expliclitly define a default clause
                    }
                    
                    tmp;
                },
              target: macro @:pos(e.pos) tink.lang.Iterate.iterator($target),
              fallback: fallback,
            };  
            
          var fallback = null,
              step = macro 1;
              
          return
            switch e {
              case macro $v += $step in $start...$end || $fallback:
                num(v, start, end, step, true, fallback);
              case macro $v += $step in $start...$end:
                num(v, start, end, step, true, fallback);
              case macro $v in $start...$end || $fallback:
                num(v, start, end, step, true, fallback);
              case macro $v in $start...$end:
                num(v, start, end, step, true, fallback);
              case macro $v -= $step in $start...$end || $fallback:
                num(v, start, end, step, false, fallback);
              case macro $v -= $step in $start...$end:
                num(v, start, end, step, false, fallback);
              case macro $e1 in $e2 || $fallback:
                normal(e1, e2, fallback);
              case macro $e1 in $e2:
                normal(e1, e2, fallback);
              case macro $i{key} => ${value} in $target:
                normal(macro $i{key} => ${value}, target, fallback);
              default: 
                e.reject('Invalid loop head: '+e.toString());
            }
        }
        
        var heads = 
          switch head.expr {
            case EArrayDecl(exprs): 
              if (exprs.length == 0) 
                head.reject();
              exprs.map(parseHead);
            default: [parseHead(head)];
          }
        
        function iterName(h:LoopHead)
          return 'iterator_${h.varName}';
          
        function iterator(h:LoopHead)
          return macro @:pos(h.target.pos) $i{'iterator_${h.varName}'};
          
        var iterators:Array<Var> = 
          [for (h in heads) {
            name: iterName(h),
            type: null,
            expr: h.target,
          }];        
        
        var items:Array<Var> = [for (h in heads) {
          name: h.varName,
          type: null,
          expr: {
            var next = macro @:pos(h.target.pos) ${iterator(h)}.next();
            if (h.fallback != null)
              next = macro @:pos(next.pos)
                if (${iterator(h)}.hasNext())
                  $next;
                else
                  ${h.fallback};
            next;
          }
        }];
                
        var cond = macro true;
            
        for (h in heads)
          if (h.fallback == null)
            cond = macro @:pos(h.target.pos) ${iterator(h)}.hasNext() && $cond;
        
        if (cond.getIdent().equals('true')) {//all heads must have had fallbacks for no change to occur
          cond = macro false;
          for (h in heads)
            cond = macro @:pos(h.target.pos) ${iterator(h)}.hasNext() || $cond;
        }
        
        init.concat([macro @:pos(e.pos) {
          ${EVars(iterators).at(e.pos)};
          while ($cond) {
            ${EVars(items).at(e.pos)};
            $body;
          }
        }]).toBlock(e.pos);
      default: e;
    }
}