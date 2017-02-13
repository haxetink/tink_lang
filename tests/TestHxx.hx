package ;

class TestHxx extends haxe.unit.TestCase {
  function test() {
    assertEquals('"example1"', Hxx.example1());
    assertEquals('"example2"', Hxx.example2());
    assertEquals('"example3"', Hxx.example3());
  }
}

@:tink class Hxx {
  static function hxx(s:String) return '"$s"';

  static public function example1() 'example1';
  static public function example2() {
    var x = function () 'example2';
    return x();
  }
  static public function example3() {
    var x = @hxx 'example3';
    return x;
  }

}