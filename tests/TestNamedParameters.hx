package ;

@:tink class TestNamedParameters extends Base {
  static var results:Array<String>;
  
  function testFunctions() {
    results = [];
    var expected = [];
    
    function tested(?length:Int = 0, ?y:Float = 0.5, z:String = '---')
      results.push('$length $y $z');
    
    tested(@with { length: 5, y: .4, z: 'yo' });
    expected.push('5 0.4 yo');
    
    tested(@with { y: 5.5, length: 4, z: 'yoyo' });
    expected.push('4 5.5 yoyo');
        
    tested(@with { length: 2, z: 'yoyo' });
    expected.push('2 0.5 yoyo');
    
    tested(@with { y: 2.3 });
    expected.push('0 2.3 ---');
    
    var obj = { length: 3, z: 'goo', blarg: 'whatever' };
    
    tested(@with obj);
    expected.push('3 0.5 goo');
    
    tested(@with 'hello');
    expected.push('5 0.5 ---');
    
    assertEquals(results.length, expected.length);
    
    for ([e in expected, r in results])
      assertEquals(e, r);
  }
  
  function testConstructors() {
    results = [];
    var expected = [];
    
    new TestedClass(@with { length: 5, y: .4, z: 'yo' });
    expected.push('5 0.4 yo');
    
    new TestedClass(@with { y: 5.5, length: 4, z: 'yoyo' });
    expected.push('4 5.5 yoyo');
        
    new TestedClass(@with { length: 2, z: 'yoyo' });
    expected.push('2 0.5 yoyo');
    
    new TestedClass(@with { y: 2.3 });
    expected.push('0 2.3 ---');
    
    var obj = { length: 3, z: 'goo', blarg: 'whatever' };
    
    new TestedClass(@with obj);
    expected.push('3 0.5 goo');
    
    new TestedClass(@with 'hello');
    expected.push('5 0.5 ---');
    
    assertEquals(results.length, expected.length);
    
    for ([e in expected, r in results])
      assertEquals(e, r);
  }
}

class TestedClass {
  public function new(?length:Int = 0, ?y:Float = .5, z:String = '---') {
    @:privateAccess TestNamedParameters.results.push('$length $y $z');
  }
}