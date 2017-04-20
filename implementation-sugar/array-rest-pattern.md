# Array Rest Pattern

Sometimes you want to pattern match against an array with specific entries at the start or the end and capture the rest. You can do this like so:

```haxe
var uris = [
    'foo/bar/x/y/z',
    'foo/baz/bar',
    'foo/bar',
];
for (i in 0...uris.length)
    switch uris[i].split('/') {
      case ['foo', 'bar', @rest rest]:
        trace(i+':'+rest);
      case ['foo', @rest rest, 'bar']:
        trace(i+':'+rest);
      case [@rest rest, 'foo', 'bar']:
        trace(i+':'+rest);
      default:
    }
```

The code will output:

```
0:[x,y,z]
1:[baz]
2:[]
```

