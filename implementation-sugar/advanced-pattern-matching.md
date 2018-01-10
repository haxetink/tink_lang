# Advanced pattern matching

## Range patterns

You can match against range *literals* like so:

```haxe
trace(switch Std.random(6) {
  case 0...3: 'nothing';
  case 3...6: 'you did it!'; 
});
```

The syntax translates `min ... max` to `_ >= min && _ < max => true`, meaning that if you match over an abstract that defines these operators, it will work too.

## Regex patterns

You can pattern match strings against regex *literals* like so:

```haxe
trace(switch input {
  case ~/.+@.+\..+/: '$input looks like an email address';
  case ~/[0-9]+/: '$input looks like a number';
  default: 'no idea what $input means';
});
```

The syntax translates to `_ != null && regex.match(_) => true`.

## Interpolation patterns

You can pattern match string against interpolated strings like so:

```haxe
switch input {
  case 'Hello, $who!': trace(who);
  default:
}
```

The above will output `'world'` when `input == 'Hello, world!'`.
