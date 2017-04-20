# Property declaration

## Pure calculated properties

You can declare purely calculated properties like this:

```haxe
@:calculated var field:SomeType = someExpr;
```

Calculated properties are [published](#publishing) and can be [infered](#inference) if you omit `SomeType`.

The above code will simply translate into:

```haxe
public var field(get, never):SomeType;
function get_field():SomeType someExpr;
```

Return statements are [added implicitly](#implicit-return) to the getter. You can also use `inline` on the variable which will cause the generation of an `inline` getter. Also `@:calc` is a recognized shortcut.

Here's what happens if we use all of these together:

```haxe
@:calc inline var data = if (Config.IS_LIVE) Data.LIVE else Data.TEST;
```

Assuming `Data.LIVE` and `Data.TEST` are of type `Foo`, this becomes:

```haxe
public var data(get, never):Foo;
inline function get_data()
    if (Config.IS_LIVE) return Data.LIVE;
    else return Data.TEST;
```

## Direct initialization

Tink allows directly initializing fields with three different options:

```haxe
var a:A = _;
var b:B = (defaultB);
var c:C = constantC;
```

Which are defined as follows:

- `_` : a constructor argument
- `(fallback)` : a constructor argument (or use `fallback` if it is null).
- or an arbitrary expression, that must be valid in the context of the constructor

Using any of these has a number of side effects:

- They will generate a constructor if none exists, with a super call if necessary. This can sometimes lead to subtle issues. If you're getting cryptic error messages in complex inheritance chains, look here.
- In the first two cases, they will add an argument to the constructor's argument list and [publish](#publishing) the constructor. Arguments are *appended* in the order of appearence. If you need them to go elsewhere, you can declare your constructor as `function new(before1, before2, _, after1, after2)`, where they will be inserted in order of appearence.
- Any initialization will cause the field to be get an `@:isVar`.

### Setter Bypass

Direct initialization will cause setter bypass. That means if your field has a setter, it will not be invoked. This is useful if you have the chicken and egg problem that your setter requires the underlying field to be in a particular state to work correctly, but to set that state you would need to call the setter. Well, here you go.

Beware that technically you can create invalid code with this.

If you don't want setter bypass, initialize the field the old fashioned way - in the constructor body.

## Lazy initialization

You can define lazily initialized fields using the `@:lazy` metadata. The implementation relies on defining an additional `tink.core.Lazy` under `lazy_<fieldName>`. Example:

```haxe
@:lazy var x = [1,2,3,4];
```

This corresponds to:
    
```haxe
@:noCompletion var lazy_x:tink.core.Lazy<Array<Int>> = tink.core.Lazy.ofFunc(function () return [1,2,3,4])
@:calc var x:Array<Int> = lazy_x.get();
```

## Property notation

### Readonly property

To denote readonly properties with a getter, you can use this syntax:

```haxe
@:readonly var x:X;

@:readonly(someExpr) var y:Y;
```

Which is converted to:

```haxe
public var x(get, null):X;
function get_x():X return x;

public var y(get, null):Y;
function get_y():Y someExpr;
```

Readonly properties are [published](#publishing), and the getters use [implicit returns](#implicit-return).  
Also, `@:read` is a recognized shortcut and you can use `inline` to cause the getter to be inlined.

### Readwrite properties

Similarly, you can define properties with both getter and setter:

```haxe
@:property var a:A;

@:property(guard) var b:B;

@:property(readC, writeC) var c:C; 
```

This will be converted into:

```haxe
@:isVar public var a(get, set):A;
function get_a() return this.a;
function set_a(param) return this.a = param;

@:isVar public var b(get, set):B;
function get_b() return this.b;
function set_b(param) return this.b = guard;

public var c(get, set):C; 
function get_c() readC;
function set_c(param) writeC;
```

These properties are also [published](#publishing), and the getters and setters use [implicit returns](#implicit-return). Also, `@:prop` is a recognized shortcut and you can use `inline` to cause the getter and setter to be inlined.

We have 3 different cases here:

- default properties - the actual value is stored in the underlying field and the getter and setter do nothing but access it
- guarded properties - the actual value is stored in the underlying field and while the getter just retrieves it, the setter uses a guard expression
- full properties - here getter and setter are really just what you define them to be. If you want to store values in the underlying field, don't forget to add `@:isVar`

Real world example:

```haxe
import Math.*;

@:tink class Point {
    static var counter = 0;
    
    @:property(max(param, 0)) var radius = .0;
    
    @:property(param % (PI * 2)) var angle = .0;
    
    @:property var name:String = 'P'+counter++;
    
    @:property(cos(angle) * radius, { setCartesian(param, y); param; }) var x:Float;
    
    @:property(sin(angle) * radius, { setCartesian(x, param); param; }) var y:Float;
    
    function setCartesian(x, y) {
        this.angle = atan2(y, x);
        this.radius = sqrt(x*x + y*y);
    }
}
```

So here we have a point that is internally represented in polar coordinates, that we can get and set. When setting these, some guards are applied, to ensure the radius never becomes negative and that the angle always stays within a certain interval. We give the point a name that can be changed. And we implement x and y as calculated settable properties.

