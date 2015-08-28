package ;

@:tink class TestNamedParameters extends Base {
  function testIt() {
    var results = [];
    var expected = [];
    
    function tested(?x:Int = 0, y:Float = 0.5, z:String = '---')
      results.push('$x $y $z');
    
    tested(@with { x: 5, y: .4, z: 'yo' });
    expected.push('5 0.4 yo');
    
    tested(@with { y: 5.5, x: 4, z: 'yoyo' });
    expected.push('4 5.5 yoyo');
        
    tested(@with { x: 2, z: 'yoyo' });
    expected.push('2 0.5 yoyo');
    
    tested(@with { y: 2.3 });
    expected.push('0 2.3 ---');
    
    assertEquals(results.length, expected.length);
    
    for ([e in expected, r in results])
      assertEquals(e, r);
  }
}