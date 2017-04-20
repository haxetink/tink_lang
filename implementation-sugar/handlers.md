# Handlers

As a counterpart to notifiers, you can use the following syntax to register handlers:

## When and Whenever

```haxe
@when(someFuture) handler;
@whenever(someSignal) handler;
@until(someFutureOrSignal) someLink;
```

These are shortcuts for:

```haxe
(someFuture : Future<Unknown>).handle(handler);
(someSignal : Signal<Unknown>).handle(handler);
(someFuture : Future<Unknown>).handle((someLink : CallbackLink));
```

If you want to only listen to the next occurrence of a `Signal` here's how:

```haxe
@when(someSignal.next()) handler;
```

Here is how you would implement drag and drop in flash/NME/OpenFL:

```haxe
class EventTools {
  static public function gets(target:EventDispatcher, event:String) {
    return Signal.ofClassical(
        target.addEventListener.bind(event),
        target.removeEventListener.bind(event),
        false
    );
  }
}

import flash.events.MouseEvent.*;
using EventTools;

@whenever(target.gets(MOUSE_DOWN)) @do {
  
  var x0 = stage.mouseX - target.x,
      y0 = stage.mouseY - target.y;
      
  @until(stage.gets(MOUSE_UP).next()) 
    @whenever(stage.gets(MOUSE_MOVE)) @do {
      target.x = stage.mouseX - x0;
      target.y = stage.mouseY - y0;
    }
    
}
```

### Compound named when

If you have many Futures you want to handle, you can use @when with an object literal, e.g.:

```haxe
var int:Future<Int> = Future.sync(5),
    float:Future<Float> = Future.sync(4.5),
		string:Future<String> = Future.sync('foo'),
		bool:Future<Bool> = Future.sync(false);
		
@when({ i: int, f: float, s: string, b: bool }) @do(o) {
	$type(o);//{ i:Int, f:Float, s:String, b: Bool }
}
```

## In and Every

```haxe
@in(delay) handler;

@every(interval) handler;
```

These get translated to:

```haxe
(haxe.Timer.delay(handler, Std.int(delay * 1000)) : CallbackLink);

{
  var timer = new haxe.Timer(Std.int(interval * 1000));
  timer.run = handler;
  (timer : CallbackLink);
}
```

Notice that the expression becomes a `CallbackLink` which allows us to use it with `@until`.

```haxe
@whenever(button.pressed) @do {
  @until(button.released.next()) 
    @every(1) @do {
      trace('tick');
    }
}
```

Which reads as "whenever the button is pressed, until it is released the next time, every second trace tick". Slightly awkward, but consider spelling it out.

