package ;

class Run {
	
	static function time(result) 
		return round(result.time);
		
	static function round(f:Float) {
		 var ret = Std.string(Std.int(f * 100) / 100);
		 return switch ret.lastIndexOf('.') {
		 	case -1: ret+'.00';
		 	case v:
		 		if (ret.length == v + 2) ret+'0';
		 		else ret;
		 }
	}
	
		
	static function main() {
		#if flash9 
			var tf = flash.Boot.getTrace();
			tf.selectable = true;
			tf.mouseEnabled = true;		
		#end
		var log:String->Void = 
			#if sys
				Sys.println;
			#elseif js
				function (msg:String) untyped console.log(msg);
			#else
				function (msg:String) trace(msg);
			#end
		Loops.run().handle(function (data) {
			log('');
			log('&nbsp;|&nbsp;|' + [for (result in data.tink) result.op].join('|'));
			log('---:|---:|' + [for (result in data.tink) '---:'].join('|'));
			log('&nbsp;|tink|' + [for (result in data.tink) time(result)].join('|'));
			log('&nbsp;|plain|' + [for (result in data.plain) time(result)].join('|'));
			log('&nbsp;|speedup|' + [for (i in 0...data.plain.length) round(data.plain[i].time / data.tink[i].time)].join('|'));
			log('');
		});
	}
}