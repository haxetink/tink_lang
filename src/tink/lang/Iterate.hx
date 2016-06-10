package tink.lang;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;
#end

class Iterate {

  static public inline function upto<T:Float>(step:T, start:T, end:T):IterUpto<T>
    return new IterUpto(step, start, end);
    
  static public inline function downto<T:Float>(step:T, start:T, end:T):IterDownto<T>
    return new IterDownto(step, start, end);
  
  macro static public function keys(e:Expr)
    return macro @:pos(e.pos) $e.keys();
    
  macro static public function getKey(target:Expr, key:Expr)
    return macro @:pos(target.pos) $target[$key];
    
  macro static public function iterator(e:Expr) {
    var ct = e.typeof().sure().toComplex();
    var ret = macro @:pos(e.pos) $e.iterator();
    
    return
      if (ret.typeof().isSuccess())
        ret;
        
      else if ((macro { ($e.hasNext() : Bool); $e.next(); } ).typeof().isSuccess()) 
        e;
    
      else if ((macro { $e[0]; ($e.length : Int); } ).typeof().isSuccess()) {
        var name = 'LengthIter' + Context.signature(ct);
        
        try 
          Context.getType(name)
        catch (e:Dynamic)
          Context.defineType(macro class $name {
            var target:$ct;
            var cur:Int;
            var max:Int;
            
            inline public function new(target) {
              this.target = target;
              this.max = target.length;
              this.cur = 0;
            }
            
            inline public function hasNext()
              return cur < max;
              
            inline public function next()
              return target[cur++];
          });
        
        return name.instantiate([e]);
      }
      else 
        e.reject('cannot iterate ' + ct.toString());
  }
    
}

class IterUpto<T:Float> {
  var cur:Int;
  var max:Int;
  var step:T;
  var offset:T;
  
  inline public function new(step:T, start:T, end:T) {
    this.step = step;
    this.offset = start;
    this.cur = 0;
    this.max = Math.ceil((end - start) / step);
  }
  
  public inline function hasNext():Bool
    return cur < max;
  
  public inline function next():T
    return offset + cur++ * step;
}

class IterDownto<T:Float> {
  var cur:Int;
  var step:T;
  var offset:T;
  
  inline public function new(step:T, start:T, end:T) {
    this.step = step;
    this.offset = end;
    this.cur = Math.ceil((start - end) / step);
  }
  
  public inline function hasNext():Bool
    return cur > 0;
  
  public inline function next():T
    return offset + --cur * step;
}