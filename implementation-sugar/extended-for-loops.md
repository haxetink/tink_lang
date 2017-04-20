# Extended For Loops

## Arbitrary steps

Loops with arbitrary steps are denoted as follows:

```haxe
//upward
for (i += step in min...max) body;
//downward
for (i -= step in max...min) body;
```

This also works for float loops. The type of `step` will determine whether this is a `Float` loop or an `Int` loop. The use of `+=` or `-=` determines whether you want an upward or downward loop. 

The downward loop is symmetrical to the upward loop, i.e. it will yield the same values, only in backward order. A upward loop will always start with min and stop just before max (except in the case of float precision issues), while an downward loop will always end with min, starting just "after" max.

Using this syntax will cause generation of a while loop.

## Key-value loops

This syntax is also supported:

```haxe
for (key => value in target) body;
```

It will just be translated into:

```haxe
for (key in target.keys()) {
    var value = target.get(key);
    body;
}
```

If `target` doesn't actually have a compatible `keys` or `get` method a type error will be generated at the position of where the `key => value` was found.

## Destructuring loops

If you wish to run a loop only to destructure the items right away, you can use this syntax:

```haxe
for (pattern in target) body;
//which is equivalent to
for (tmp in target)
  switch tmp {
        case pattern: body;
        default:
    }
```

Here is an example:

```haxe
var a = [Left(4), Right('foo'), Right('bar'), Left(5), Left(6)];

trace([for (Left(x) in a) x]);//[4, 5, 6]
trace([for (Right(x) in a) x]);//['foo', 'bar']
```

You may notice that `pattern` being an identifier is indeed just a special case of this rule.

```haxe
for (v in 0...100) {}
//is equivalent to:
for (tmp in 0...100) 
    switch tmp {
        case v: //this matches everything
    }
```

However, to keep the code simple, tink does not generate the switch statement for mere identifiers.

## Parallel loops

Sometimes you want to iterate over multiple targets at once. Tink supports this syntax:

```haxe
for ([head1, head2, head3]) body;
```

Here `head1`, `head2` and `head3` can be normal loop heads (`variable in expression`) or loop heads for arbitrary step or key-value loops (please note that using parallel loops for key-value loops only makes sense if key order is deterministic, i.e. you're using an ordered map or something).

Example:

```haxe
for ([ship in ships, i -= 1 in ships.length...0])
    ship.x = 30 * i;
```

This will order the ships in your array from right to left.

By default, a parallel loop will stop as soon as any head is "depleted". Another example, to show just that:

```haxe
var girls = ['Lilly', 'Peggy', 'Sue'];
var boys = ['Peter', 'Paul', 'Joe', 'John', 'Jack'];
for ([girl in girls, boy in boys])
    trace(girl + ' loves ' + boy);
```

Output:

```
Lilly loves Peter
Peggy loves Paul
Sue loves Joe
```

Now that's really unfortunate for John and Jack. Luckily there's one person they can always lean on: 

```haxe
var girls = ['Lilly', 'Peggy', 'Sue'];
var boys = ['Peter', 'Paul', 'Joe', 'John', 'Jack'];
for ([girl in girls || 'Mommy', boy in boys])
    trace(girl + ' loves ' + boy);
```

Output:

```
Lilly loves Peter
Peggy loves Paul
Sue loves Joe
Mommy loves John
Mommy loves Jack
```

### Loop Fallbacks

As we see in the example just above, we can provide *fallbacks* for parallel loops. We simply use `||` for this. As soon as a loop target is depleted, the fallback expression is used instead. Please note that the expression is evaluated *every time* a fallback value is needed. Example:

```haxe
var girls = ['Lilly', 'Peggy', 'Sue'];
var boys = ['Peter', 'Paul', 'Joe', 'John', 'Jack', 'Jeff', 'Josh'];
var index = 0;
var family = ['Mommy', 'Grandma', 'Aunt Lilly'];
for ([girl in girls || family[index++ % family.length], boy in boys])
    trace(girl + ' loves ' + boy);
```

Output:

```
Lilly loves Peter
Peggy loves Paul
Sue loves Joe
Mommy loves John
Grandma loves Jack
Aunt Lilly loves Jeff
Mommy loves Josh
```

This is very powerful, but it's also a great way to shoot yourself in the foot. Please use non-constant expressions with care.

If you specify fallbacks for all targets, the loop will stop as soon as all targets are depleted and only fallbacks are available.

## Extended comprehensions

Tink generalizes the concept of for comprehensions in two ways. It deals with more complex loop bodies and it allows to construct things other than arrays.

### Complex bodies

Haxe comprehensions are rather narrow in what they accept as bodies. In a number of cases the behavior is unintuitive:

Example with `switch`:

```haxe
var x = [true, false, true];

trace([for (x in x)
    if (x) 1;
]);//[1, 1]

var x = [true, false, true];
trace([for (x in x)
    switch x {
        case true: 1;
        default:
    }
]);//[1, 1] with tink_lang, compiler error "Void should be Int" with vanilla Haxe 
```

Example with arbitrary `if`:

```haxe
typedef Person = { name: String, age:Int, male:Bool }
enum Rescued {
    Woman(person:Person);
    Child(person:Person);
}

var crew:Array<Person> = [
    { name : 'Joe', age: 25, male: true }, 
    { name : 'Jane', age: 24, male: false }, 
    { name: 'Timmy', age: 8, male: true }
];

var womenAndChildren = [for (person in crew)
    if (person.age < 18) Child(person)
    else if (!person.male) Woman(person)
];
```

With plain Haxe this will not compile saying "Void should be Rescued".

The vanilla Haxe behavior helps avoiding mistakenly empty branches. The idea has merit. This library has a different approach. By default, tink_lang will just follow down all paths to see if there is something to be returned. You can always use [manual yielding](#manual-yielding) if you need more control.

### Alternative output

Haxe comprehensions can only construct maps or arrays. Tink comprehensions have a broader spectrum and deal with maps and arrays as special cases.

The general structure of a tink comprehension is:

```haxe
target.method(for (head) body)
```

This gets translated to something like

```haxe
{
    var tmp = target;
    for (head) bodyCallingMethod;
    tmp;
}
```

Where the body is transformed so that the leaf expressions call `tmp.method`.

If the method requires more than one argument, you can use `_(arg1, arg2, arg3)` to yield multiple values. Example:

```haxe
var peopleByName = new Map().set(for (person in people) _(person.name, person));
```

This is translated into:

```haxe
var peopleByName = {
    var tmp = new Map();
    for (person in people) 
        tmp.set(person.name, person);
    tmp;
}
```

When tink encounters `[for (head) body]` it will simply translate it into `[].push(for (head) body)` before processing, and when it encounters something like `[for (head) key => val]` it will translate it into `new Map().set(for (head) _(key, val))`, and they will thus work as though transformed by the Haxe compiler.

But if you need to output a list, you can do:

```haxe
new List().add(for (i in 0...100) i)
```

But you needn't *construct* the target. You can use an existing one. For example to draw a couple of rectangles on the same sprite:

```haxe
sprite.graphics.drawRect(
    for (i in 0...10) 
        _(0, i*20, 100, 10)
)
```

Also, because the target is returned, you can chain stuff:

```haxe
var upAndDown = new List()
    .add(for (i in 0...5) i)
    .add(for (i -= 1 in 5...0) i)
trace(upAndDown);//{0, 1, 2, 3, 4, 4, 3, 2, 1, 0}
```

### Manual yielding

If your loop body contains an expression such as `@yield $value`, then instead of gathering the result automatically, the comprehension will only add to the output what you yield, which allows you to have multiple results per loop iteration.

```haxe
var ret = [for (i in 1...5) {
    if (i == 1) @yield 0;
    @yield -i;
    @yield i;
}];
trace(ret);//[0, -1, 1, -2, 2, -3, 3, -4, 4];
```

