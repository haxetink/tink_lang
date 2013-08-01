package ;

import tink.core.Future;
import tink.lang.Sugar;

class TestFutureDecl extends Base implements Sugar {
	@:future var some:Int;
	@:future var ten = Future.ofConstant(10);
	function testConst() {
		var val = null;
		ten.when(function (v) val = v);
		assertEquals(10, val);
	}
	function testOwn() {
		var val = null;
		some.when(function (v) val = v);
		assertEquals(null, val);		
		_some.invoke(10);
		assertEquals(10, val);		
	}
}