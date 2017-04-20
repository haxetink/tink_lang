# Default

Default allows you to deal with sentinel or default values (such as `null`, `-1`, `0`). Instead of writing this code:

```haxe
var x = someComplexExpression;
if (x == null) x = defaultValue;
doSomething(x)
```

You would write:

```haxe
doSomething(someComplexExpression | if (null) defaultValue);
```

Read this syntax as "use `someComplexExpression` or if `null` use `defaultValue`". There's really not much to it. It helps avoiding additional variables. If you need to check against more than one value a switch statement is more appropriate.

