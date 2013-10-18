package ;

import tink.Lang;

class TestFutureDecl extends Base implements Lang {
	@:future var ten = tink.core.Future.sync(10);
	@:future var some:Int;
	function testConst() {
		var val = null;
		ten.handle(function (v) val = v);
		assertEquals(10, val);
	}
	function testOwn() {
		var val = null;
		some.handle(function (v) val = v);
		assertEquals(null, val);		
		_some.trigger(10);
		assertEquals(10, val);		
	}
}