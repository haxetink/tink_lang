package ;

import haxe.PosInfos;
import haxe.unit.TestCase;
import haxe.unit.TestResult;
import haxe.unit.TestStatus;
import tink.core.Either;

abstract PhysicalType<T>(Either<Class<T>, Enum<T>>) {
	
	function new(v) this = v;
	
	public function toString() 
		return 
			switch this {
				case Left(c): Type.getClassName(c);
				case Right(e): Type.getEnumName(e);
			}
			
	public function check(v:T) 
		return 
			Std.is(v, this.getParameters()[0]);
	
	@:from static function ofClass<C>(c:Class<C>) 
		return new PhysicalType(Left(c));
		
	@:from static function ofEnum<E>(e:Enum<E>) 
		return new PhysicalType(Right(e));
}
//TODO: this helper should go somewhere
class Base extends TestCase {
	function fail(msg:String, ?c : PosInfos) {
		currentTest.done = true;
		currentTest.success = false;
		currentTest.error = msg;
		currentTest.posInfos = c;
		throw currentTest;
	}
	function throws<A>(f:Void->Void, t:PhysicalType<A>, ?check:A->Bool, ?pos:PosInfos):Void {
		try f()
		catch (e:Dynamic) {
			if (!t.check(e)) fail('Exception $e not of type $t', pos);
			if (check != null && !check(e)) fail('Exception $e does not satisfy condition', pos);
			assertTrue(true);
			return;
		}
		fail('no exception thrown', pos);
	}
}