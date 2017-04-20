# Type switch

With tink you can switch over an expression's type like so:
    
```haxe
switch expr {
    case (name1 : Type1):
    case (name2 : Type2):
    case (name3 : Type3):
        ...
    default:
}
```

A default clause is mandatory. Also expr must be of the type you are switching against, so if for example you want to use this for downcasting, you will need to do `switch (expr : Dynamic) { ... }` or something equivalent.

Simple example:
    
```haxe
var value:haxe.extern.EitherType<Int, String> = 5;

switch value {
    case (i : Int): trace('int $i');
    case (s : String): trace('string $s');
    default:
}
```

Put together with a destructuring loop:

```haxe
var fruit:Array<Any> = [new Apple(), new Apple(), new Banana(), new Apple(), new Kiwi()];
var apples = [for ((a : Apple) in fruit) a];
trace(apples.length);//3
```

