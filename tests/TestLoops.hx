package ;

import haxe.ds.Either;

abstract Arrayish(Array<Int>){
  public var length(get, never):Int;
  public function new() this = [for (i in 0...100) i];
  inline function get_length() return this.length;
  @:arrayAccess inline function get(index:Int) 
    return this[index];
    
  public inline function toArray()
    return this;
}

@:tink class TestLoops extends Base {
  function testAbstract() {
    var a = new Arrayish();
    for ([i in a, j in a.toArray()]) 
      assertEquals(j, i);
  }
  function testArray() {
    var a = [for (i in 0...100) Std.string(i)];
    var l = Lambda.list(a),
      sm = [for (x in a) x => x],
      im = [for (x in a) Std.parseInt(x) => x];
    inline function sort<T>(a:Array<T>) {
      var ret = a.join(',').split(',');
      ret.sort(Reflect.compare);
      return ret.join(',');      
    }      
    
    assertEquals(sort(a), sort([for ([i in sm.keys()]) i]));
    assertEquals(sort(a), sort([for ([i in im.keys()]) i]));
    
    assertEquals(sort(a), sort([for ([i in sm]) i]));
    assertEquals(sort(a), sort([for ([i in im]) i]));
    
    for ([x in a, i in 0...a.length])
      assertEquals(Std.string(i), x);
    
    for ([x in l, i in 0...l.length])
      assertEquals(Std.string(i), x);
  }

  function testYielding() {
    var ret = [for (i in 1...5) {
      if (i == 1) @yield 0;
      @yield -i;
      @yield i;
    }];
    compareArray([0, -1, 1, -2, 2, -3, 3, -4, 4], ret);
  }
  function testMatching() {
    var a = [Left(4), Right('foo'), Right('bar'), Left(5), Left(6)];
    
    compareArray([4, 5, 6], [for (Left(x) in a) x]);
    compareArray(['foo', 'bar'], [for (Right(x) in a) x]);
  }
  
  //function testCounter() {
    //var a = [for (i in 0...100) i];
    //for ([i in 0...100, j++]) {
      //assertEquals(a[i], j);
    //}
  //}
  
  function compareFloatArray(expected:Array<Float>, found:Array<Float>) {
    assertEquals(expected.length, found.length);
    for (i in 0...expected.length) 
      assertTrue(Math.abs(expected[i] - found[i]) < .0000001);
  }
  function compareArray<A>(expected:Array<A>, found:Array<A>) {
    assertEquals(expected.length, found.length);
    for (i in 0...expected.length) 
      assertEquals(expected[i], found[i]);
  }
  
  function testForLoops() {
    var loop = new SuperLooper(),
      control = new ControlLooper();
    
    function floatUp(start:Float, end:Float, step:Float, ?breaker) {
      if (breaker == null) breaker = function (_) return false;
      compareFloatArray(
        control.floatUp(start, end, step, breaker),
        loop.floatUp(start, end, step, breaker)
      );
    }
    function floatDown(end:Float, start:Float, step:Float, ?breaker) {
      if (breaker == null) breaker = function (_) return false;
      compareFloatArray(
        control.floatDown(start, end, step, breaker),
        loop.floatDown(start, end, step, breaker)
      );
    }
    function intUp(start, end, step, ?breaker) {
      if (breaker == null) breaker = function (_) return false;
      compareArray(
        control.intUp(start, end, step, breaker),
        loop.intUp(start, end, step, breaker)
      );
    }
    function intDown(end, start, step, ?breaker) {
      if (breaker == null) breaker = function (_) return false;
      compareArray(
        control.intDown(start, end, step, breaker),
        loop.intDown(start, end, step, breaker)
      );
    }  
    
    compareFloatArray(
      control.floatUp(0.1, 2.9, 0.5, function (_) return false),
      [0.1, 0.6, 1.1, 1.6, 2.1, 2.6]
    );
    
    compareArray(
      control.intUp(3, 17, 4, function (_) return false),
      [3, 7, 11, 15]
    );
    
    compareFloatArray(
      control.floatUp(0, 10, .3, function (_) return false),
      {
        var a = control.floatDown(10, 0, .3, function (_) return false);
        a.reverse();
        a;
      }
    );
    
    compareArray(
      control.intUp(0, 100, 3, function (_) return false),
      {
        var a = control.intDown(100, 0, 3, function (_) return false);
        a.reverse();
        a;
      }
    );

    for (i in 1...50) {
      floatUp(.0, i * 1.0, .1);
      floatUp(.0, 0.1 * i, .1);
      
      var breakAt = (i >>> 1) + Std.random(i);
      
      floatUp(0, i, 1.0, function (i) return i >= breakAt);
      intUp(0, i, 3);
      intUp(0, 3 * i, 3);
      
      var breakAt = (i >>> 1) + Std.random(i);
      
      intUp(0, i, 1, function (i) return i >= breakAt);
      floatDown(0, i, .1);
      floatDown(0, 0.1 * i, .1);
      
      var breakAt = (i >>> 1) + Std.random(i);
      
      floatDown(0, i, 1.0, function (i) return i >= breakAt);
      intDown(0, i, 3);
      intDown(0, 3 * i, 3);
      
      var breakAt = (i >>> 1) + Std.random(i);
      intDown(0, i, 1, function (i) return i >= breakAt);
    }
    
    assertEquals('0:9,1:8,2:7,3:6,4:5,5:4,6:3,7:2,8:1,9:0', loop.complexComprehension(0, 10, 10, 0, 1).join(','));
    assertEquals('0:9,1:8,2:7', loop.loopMap([0 => 9, 1 => 8, 2 => 7]).join(','));
    
  }
  
}


class ControlLooper {
  public function new() { }
  public function floatUp(start:Float, end:Float, step:Float, breaker) {
    var ret = [];
    for (i in 0...Math.ceil((end - start) / step)) {
      var i = i * step + start;
      if (breaker(i)) break;
      ret.push(i);
    }
    return ret;
  }
  public function floatDown(start:Float, end:Float, step:Float, breaker) {
    var ret = [];
    var count = Math.ceil((start - end) / step);
    for (i in 0...count) {
      var i = (count - i - 1) * step + end;
      if (breaker(i)) break;
      ret.push(i);
    }
    return ret;
  }
  public function intUp(start:Int, end:Int, step:Int, breaker) {
    var ret = [];
    for (i in 0...Math.ceil((end - start) / step)) {
      var i = i * step + start;
      if (breaker(i)) break;
      ret.push(i);
    }
    return ret;
  }
  public function intDown(start:Int, end:Int, step:Int, breaker) {
    var ret = [];
    var count = Math.ceil((start - end) / step);
    for (i in 0...count) {
      var i = (count - i - 1) * step + end;
      if (breaker(i)) break;
      ret.push(i);
    }
    return ret;
  }  
}

@:tink class SuperLooper {
  public function new() { }
  public function floatUp(start:Float, end:Float, step:Float, breaker)
    return [for (i += step in start...end) {
      if (breaker(i)) break;
      i;
    }];
  
  public function floatDown(start:Float, end:Float, step:Float, breaker) 
    return [for (i -= step in start...end) {
      if (breaker(i)) break;
      i;
    }];
  
  public function intUp(start:Int, end:Int, step:Int, breaker) 
    return [for (i += step in start...end) {
      if (breaker(i)) break;
      i;
    }];

  public function intDown(start:Int, end:Int, step:Int, breaker)
    return [for (i -= step in start...end) {
      if (breaker(i)) break;
      i;
    }];

  public function complexComprehension(imin, imax, jmax, jmin, step:Int)
    return [for ([i in imin...imax, j -= step in jmax...jmin]) '$i:$j'];
  
  public function loopMap(m:Map<Int, Int>) {
    var ret = [for (k => v in m) '$k:$v'];
    ret.sort(Reflect.compare);
    return ret;
  }
}