package;
import haxe.unit.TestCase;
import tink.core.Future;

@:tink class TestWhen extends TestCase {
  function testSimple() {
    @when(Future.sync(5)) assertEquals.bind(5, _);    
  }
  
  function testNamed() {
    @when({ foo: Future.sync(5) }) switch _ {
      case { foo: foo } :
        assertEquals(5, foo);
    }
  }
  function testCompound() {
    var res = null;
    
    var int = Future.trigger(),
        float = Future.trigger(),
        string = Future.trigger(),
        bool = Future.trigger();
    
    @when({ i: int, f: float, s: string, b: bool }) @do(o) {
      res = o;
    }
    
    assertEquals(res, null);
    
    int.trigger(4);
    assertEquals(res, null);
    
    float.trigger(4.5);
    assertEquals(res, null);
    
    string.trigger('yo');
    assertEquals(res, null);
    
    bool.trigger(true);
    assertFalse(res == null);
    
    assertEquals(4, res.i);
    assertEquals(4.5, res.f);
    assertEquals('yo', res.s);
    assertEquals(true, res.b);
  }
  
}