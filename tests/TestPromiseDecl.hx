package ;

using tink.CoreApi;

@:tink class TestPromiseDecl extends Base {
  @:promise var ten = 10;
  @:promise var some:Int;
  function testConst() {
    var val:Null<Int> = null;
    ten.handle(function (v) val = v.sure());
    assertEquals(10, val);
  }
  function testOwn() {
    var val:Null<Int> = null;
    some.handle(function (v) val = v.sure());
    assertEquals(null, val);    
    _some.trigger(Success(10));
    assertEquals(10, val);    
  }
}