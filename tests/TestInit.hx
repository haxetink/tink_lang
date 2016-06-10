package ;

import haxe.ds.StringMap;
using Lambda;

class TestInit extends Base {
  function test() {
    var d = new Dummy('x');
    
    assertEquals('x', d.bar);
    assertEquals(Dummy.value, d.foo);
    assertEquals('baz', d.baz);
    
    d = new Dummy('y', 'zab');
    
    assertEquals('y', d.bar);
    assertEquals(Dummy.value, d.foo);
    assertEquals('zab', d.baz);
  }
}

@:tink private class Dummy {
  static public var value = [1,2,3];
  public var foo:Array<Int> = Dummy.value;
  public var bar:String = _;
  public var baz = ('baz');
}