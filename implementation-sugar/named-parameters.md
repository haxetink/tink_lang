# Named Parameters

You can use `@with` metadata to invoke an arbitrary function or constructor with named parameters, that exist as fields on an object.

## Named Parameters with object literals

This example with OpenFL's [`TextFormat`](http://docs.openfl.org/openfl/text/TextFormat.html#new) and 
[`BitmapData`](http://docs.openfl.org/openfl/display/BitmapData.html#copyPixels) should illustrate the idea:
  
```haxe 
var format = new openfl.text.TextFormat(@with { underline: true, size: 15 });//oh yeah!

var someBmp = new openfl.display.BitmapData(500, 400);
someBmp.copyPixels(@with {
  destPoint: somePoint,
  sourceBitmapData: someSource,
  sourceRect: someRect,
});
```

As you can see, ordering does not matter.

## Named Parameters with object references

Instead of defining an object literal at the call site, you may also use a reference to an arbitrary object and have that splatted onto the argument list. The `TextFormat` example above would now look like so:
  
```haxe
@:tink class Margins {
  var leftMargin:Float = _;
  var rightMargin:Float = _;
}
var margins = new Margins(10, 20);
var format = new openfl.text.TextFormat(@with margins);
```

## Named Parameter caveats

Named parameters don't play too well with Haxe, because of how the language treats parameters names. 
The compiler makes some effort track names, but that is only to make error messages more readable, i.e. "`<theError>` for function argument `<theName>`". Other than that, it does not care. At all.

When using named parameters, you are extending function types to depend also on their names. This deviates from Haxe semantics and as a result may badly impact your code.
If you rely on argument names, you will have to accept that library authors may change them, unaware of the problems it might cause you. You will also have to accept, 
that the implementor of an interface or the subclass of a class may change the argument name of a method, and depending on which concrete type you call against, 
you may have to use different names. This means that if you change a type to something that the compiler considers fully compatible, you may still get errors.

Therefore you should use named parameters sparsingly. If you feel the need to use named parameters when calling against an API that you control, then change the API. 
If you design an API in such a way that its consumers will need named parameters to not want to rip their eyes out, change the API.
Named parameters only serve as a workaround for interfaces that should be improved to start with. You can use tink_lang's [function options](#function-options), or better yet, 
instead of passing a big hunk of values, write the function against an interface that defines the behavior that the data would parametrize. Example:

```haxe
//BAD:
class Box {
  function new(marginTop:Int, marginBottom:Int, marginLeft:Int, marginRight:Int, minWidth:Int, maxWidth:Int, minHeight:Int, maxHeight:Int);
}

//GOOD:
interface Layout {
  function calculateBounds(available:Rect):Rect;  
}

class Box {
  function new(layout:Layout);
}
```

You can the go an implement miriads of layouts, with margins, without and what not. And your users can too.

There are of course cases, where there's simply no way around, particularly if you hit a performance bottleneck. But those are the exceptions to a general rule.

Use named parameters to call against 3rd party APIs that are set in stone. For everything else, carefully explore other options first.

