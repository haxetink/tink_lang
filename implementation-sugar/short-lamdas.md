# Short lambdas

Tink supports a multitude of notations for short lambdas. Generally, two different kinds of functions are distinguished: those that return values and those that don't. The distinction is necessary since Haxe no longer allows values of type `Void`. We'll be calling them functions and procedures respectively (as is the case in Pascal).

Currently, Haxe does not support short lambdas, the rationale being that they are harder to read to new comers. This concern does have its value. Use this notation to increase readability and not to obfuscate code for the sake of saving a few key strokes. As the name would suggest, short lambdas should be *short*, the motivation here being to write function inline with minimal noise, which by nature is not compatible with complex bodies. If you have some complex, **give it a name** (you can always use a nested function and declare it `inline`).

## Arrow lambda

The notation looks like `[...args] => body`, with a shortcut for exactly one argument `arg => body`. Examples:

* `[] => true` becomes `function () return true`
* `[x] => 2 * x` becomes `function (x) return 2 * x`
* `x => 2 * x` (special case) becomes `function (x) return 2 * x`
* `[x, y] => x + y` becomes `function (x, y) return x + y`

Arrow lambdas are always funtions, since the arrow is conventionally used to represent a mapping (as in map literals, map comprehensions and extractors). A procedure does not define a mapping.

## Do procedures

This notation uses inline metadata to add a "keyword" as follows.

* `@do trace('foo')` becomes `function () trace('foo')`
* `@do(who) trace('hello $who')` becomes `function (who) trace('hello $who')`

Please note that metadata has precedence over binary operations. So `@do x = 5` will become `(function () x) = 5` which is an invalid statement. It's best to use `@do` with a block for a body, as that will assure the right precendence and should also look familiar to Ruby programmers.

Combined with [trailing arguments](#trailing-arguments), you can write things like:

```haxe
myButton.on('click') => @do {
    trace('click');
    triggerSomeAction();
}
```

Or why not some nodejs code:

```haxe
fs.readFile('config') => @do(error, data)
    if (error != null) panic(error);
    else
        http.get(Json.parse(data).someURL) => @do(error, data)
            if (error != null) panic(error);
            else {
                trace('we have the data')
            }
```

## F functions

Similarly to [do procedures](#do-procedure), `@f` will create a function:

* `@f 4` becomes `function () return 4`
* `@f(who) 'hello $who'` becomes `function (who) return 'hello $who')`

## Matchers

Another kind of short lambdas are "matchers", where the arguments are directly piped into a switch statement and therefore needn't be named (since you will capture the values you need in the respective case statements).

```haxe
@do switch _ {
    /* cases */
}

switch _ {
    /* cases */
}
```

Which become:

```haxe
function (tmp) switch tmp {
    /* cases */
}

function (tmp) return switch tmp {
    /* cases */
}
```

For the sake of consistency `@f switch _ {}` is treated like `switch _ {}`.

### Multi argument matchers

If you expect more than one argument, you can use `[_,_]`, `[_, _, _]` and so on:

```haxe
// or alternatively
@do switch [_, _] {
    /* cases */
}
```

Each of which becomes:

```haxe
function (tmp1, tmp2) switch [tmp1, tmp2] {
    /* cases */
}
```

Put together with [trailing arguments](#trailing-arguments), you can write code like this:

```haxe
someOp() => switch _ {
    case Success(result):
    case Failure(error):
}
```

