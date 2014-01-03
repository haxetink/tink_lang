package ;

import tink.Lang;

using tink.CoreApi;

class TestDispatch extends Base implements Lang {
	function testStringly() {
		
	}
}

private class Stringly implements Lang {
	var handlers = new Array<Pair<String, Int->Void>>();
	var counter = 0;
	
	public function new() {}
	
	public function addListener(event:String, handler:Int->Void):Void {
		removeListener(event, handler);
		handlers.push(new Pair(event, handler));
	}
	
	public function removeListener(event:String, handler:Int->Void):Void 
		for (r in [for (h in handlers) if (Reflect.compareMethods(h.b, handler)) h])
			handlers.remove(r);
	
	public function trigger(event:String) {
		var arg = counter++;
		for (h in handlers)
			if (h.a == event) 
				(h.b)(arg);
	}
}