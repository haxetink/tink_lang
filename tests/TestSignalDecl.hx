package ;

@:tink class TestSignalDecl extends Base {
  
  @:signal var foo:Int;
  @:signal var bar = this.foo.map([i] => 2 * i);
  
  function test() {
    var r = [];
    
    function compare(expected:Array<Int>)
      for ([expected in expected, result in r])
        assertEquals(expected, result);
      
    foo.handle(r.push);
    bar.handle(r.push);
    
    _foo.trigger(4);
    compare([8, 4]);
    _foo.trigger(5);
    compare([8, 4, 10, 5]);
  }
  
  function testDocsExample() {
    var o = new Observable(100);
    var a = [];
    
    function add(e:MouseEvent)
      a.push(e.x);
      
    o.clickLeft.handle(add);
    o.click.handle(add);

    @:privateAccess o._click.trigger({ x: 80 });
    @:privateAccess o._click.trigger({ x: 20 });
    
    assertEquals('80,20,20', a.join(','));
    
    var fired = false;
    o.jsonData.handle(function (data) {
      fired = true;
      assertEquals(Std.string([1,2,3]), Std.string(data));
    });
    assertFalse(fired);
    
    @:privateAccess o._data.trigger(haxe.io.Bytes.ofString('[1,2,3]'));
    
    assertTrue(fired);
  }
}

typedef MouseEvent = { x: Float };

@:tink class Observable {
  var width:Float = _;
  @:signal var click:MouseEvent;
  @:future var data:haxe.io.Bytes;
  @:signal var clickLeft = this.click.filter(function (e:MouseEvent) return e.x < this.width / 2);
  @:future var jsonData = this.data.map(function (b) return b.toString()).map(haxe.Json.parse);
}
