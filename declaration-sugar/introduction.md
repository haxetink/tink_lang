# Declaration Sugar

A few general notes/concepts apply:

## Publishing

Tink has the concept of *publishing* members. This means that a member not explicitly declared `private` is promoted to become `public`, which is contrary to the default in Haxe. Tink does not publish everything by default, but certain sugar makes it sensible to *publish* a field.

## Inference

Tink also tries to infer types that you omit that would be mandatory. However currently it will not be able to infer an expression that uses members from the class itself.

## Implicit Return

In many cases, it's obvious that an expression should actually `return` something. Tink handles many of these by implicitly adding return statements should you omit them.

The strategy is all-or-nothing, i.e. if you have *no* return statements, tink will add them. If you have one, tink will leave things as they are.

Examples:

```haxe
{
    if (foo) return 5;
    x;
    y;
    z;
}
```

This will not be touched and will ultimately result in a type error like "Void should be Int".

```haxe
if (foo) 5;
else {
    x;
    y;
    z;
}
```

This will be transformed into:

```haxe
if (foo) return 5;
else {
    x;
    y;
    return z;
}
```

When adding implicit return statements

- to a block, they are added to the last statement
- to an `if`, they are added to the if branch and the else branch if present
- to a `switch`, they are added to each branch
- any other expression is returned directly

As a corrolary, an implicit return of a loop will not lead to meaningful code.