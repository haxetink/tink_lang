package;

import haxe.ds.Either;
import haxe.ds.Option;
import haxe.unit.TestCase;

using tink.CoreApi;

@:tink class TestSwitch extends TestCase {
  function testRest() {
    assertTrue() => switch '1,2,3,4,5'.split(',') {
      case [first, @rest r, last]:
        assertEquals('1', first);
        assertEquals('5', last);
        assertEquals('2,3,4', r.join(','));
        true;
      default: false;
    }
    assertTrue() => switch '1,5'.split(',') {
      case [first, @rest r, last]:
        assertEquals('1', first);
        assertEquals('5', last);
        assertEquals('', r.join(','));
        true;
      default: false;
    }
  }
  
  function testType() {
    var a:Array<Dynamic> = [1, true, 5.2, 'foo', [], new Foo(), None, Left(3)];
    
    assertEquals('i1,btrue,f5.2,sfoo,a0,oyo!,n,u') => [for (v in a) switch v {
      case (i : Int): 'i$i';
      case (b : Bool): 'b$b';
      case (f : Float): 'f$f';
      case (s : String): 's$s';
      case (a : Array<Dynamic>): 'a'+a.length;
      case (o : Foo): 'o' + o.foo();
      case (o : Option<Dynamic>): 
        switch o { 
          case None: 'n'; 
          default: 
        }
      default: 'u';
    }].join(',');
    
    var values:Array<haxe.extern.EitherType<Int, String>> = [5, 'foo'];

    assertEquals('int 5,string "foo"') => [for (value in values) switch value {
      case (i : Int): 'int $i';
      case (s : String): 'string "$s"';
      default:
    }].join(',');
    
    var fruit:Array<Any> = [new Apple(), new Apple(), new Banana(), new Apple(), new Kiwi()];
    var apples:Array<Apple> = [for ((a : Apple) in fruit) a];
    
    for (a in apples)
      assertTrue(Std.is(a, Apple));
      
    assertEquals(3, apples.length);
  }

  function testRange() {
    var string = 'Hello, world!';

    assertEquals('ulllloslllllo', [for (i in 0...string.length) switch string.charCodeAt(i) {
      case 'A'.code ... 'Z'.code + 1: 'u';
      case 'a'.code ... 'z'.code + 1: 'l';
      case 0 ... ' '.code + 1: 's';
      default: 'o';
    }].join(''));
  }

  function testRegex() {
    var strings = [{ s: 'foo' }, { s: 'bar' }, { s: null }];
    for (o in strings)
      switch o {
        case { s: ~/foo/ }: assertEquals('foo', o.s);
        case { s: ~/bar/ }: assertEquals('bar', o.s);
        default: assertEquals(null, o.s);
      }
  }
}

private class Foo {
  public function new() { }
  @:extern public inline function foo():String return 'yo!';
}


private class Apple { public function new() {} }
private class Banana { public function new() {} }
private class Kiwi { public function new() {} }