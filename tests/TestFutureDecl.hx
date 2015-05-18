package ;

@:tink class TestFutureDecl extends Base {
	@:future var ten = tink.core.Future.sync(10);
	@:future var some:Int;
	function testConst() {
		var val:Null<Int> = null;
		ten.handle(function (v) val = v);
		assertEquals(10, val);
	}
	function testOwn() {
		var val:Null<Int> = null;
		some.handle(function (v) val = v);
		assertEquals(null, val);		
		_some.trigger(10);
		assertEquals(10, val);		
	}
}