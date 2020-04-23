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

    assertTrue(d.issue5[12]);
    assertFalse(d.issue5[12]);
  }
}

@:tink private class Dummy {
  static public var value = [1,2,3];
  public var foo:Array<Int> = Dummy.value;
  public var bar:String = _;
  public var baz = @byDefault 'baz';
  public var issue5 = [12 => true, 14 => false];
}