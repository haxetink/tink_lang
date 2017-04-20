# Syntactic Delegation

Tinkerbell supports syntactic delegation for both fields and methods. The basic idea is, that you can automatically have the delegating class call methods or access properties on the objects it is delegating to. In the simpler of two cases, the class delegates to one of its members. A very simple example:

```haxe
@:tink class Stack<T> {
    @:forward(push, pop, iterator, length) var elements:Array<T>;
    public function new() {
        this.elements = [];
    }
}
```

Here, we are forwarding the calls `push`, `pop`, `iterator` as well as the field `length` to the underlying data-structure. 

Another example:

```haxe
@:tink class OrderedStringMap<T> {
    var keyList:Array<String> = [];
    @:forward var map:haxe.ds.StringMap<T> = new haxe.ds.StringMap<T>();
    public function new() {}
    public function set(key:String, value:T) 
        if (!exists(key)) {
            keyList.push(key);
            map.set(key, value);
        }
    public function remove(key:String) 
        return map.remove(key) && keyList.remove(key)
    public function keys() 
        return keyList.iterator()
}
```

## Delegation filters

As you have seen in the above example, we chose which fields to forward. What we are doing here is matching a field against a filter. The rules:

* An identifier matches the field with the same name
* A regular expression matches all fields with matching names
* A string matches all fields matching it, with the `*`-character being matching any character sequence, i.e. `do*` would match all members starting with "do" and `*Slot` matches all members ending with "Slot"
* `filter_1 | filter_2` and `filter_1 || filter_2` match if either filter matches
* `[filter_1, ..., filter_n]` matches if either of the filters match
* `filter_1 & filter_2` and `filter_1 && filter_2` match if both filters match
* `!filter` matches if `filter` doesn't match

If the `@:forward`-tag has no arguments, then all fields are matched. Otherwise all fields matching either argument are matched.

Also `@:fwd` is a recognized shortcut for `@:forward`.

## Delegation to member

Usage example:

```haxe
//let's take two sample classes
class Foo {
    public function fooX(x:X):Void;
    public function yFoo():Y;
}
class Bar {
    public var barVar:V;
    public function doBar(a:A, b:B, c:C):R;
}
//and now we can do
@:tink class FooBar {
    @:forward var foo:Foo;
    @:forward var bar:Bar;
}
//which corresponds to
@:tink class FooBar {
    var foo:Foo;
    var bar:Bar;
    public function fooX(x) return foo.fooX(x)
    public function yFoo() return foo.yFoo()
    @:prop(bar.barVar, bar.barVar = param) var barVar:V;//see property notation
    public function doBar(a, b, c) return bar.doBar(a,b,c)
}
```

## Delegation to method

This kind of forwarding may appear a little strange at first, but let's see it in action:

```haxe
//Foo and Bar defined in the example above
@:tink class FooBar2 {
    var fields:Map<String, Dynamic>;
    @:forward function anyName(foo:Foo, bar:Bar) {
        get: fields.get($name),
        set: fields.set($name, param),
        call: trace('calling '+$name+' on '+$id+' with '+$args)
    }
}
```

This becomes (actually this is simplified for your convenience):

```haxe
@:tink class Foobar2 {
    var fields:Map<String, Dynamic>;
    public function fooX(x:X) trace('calling '+'fooX'+' on '+'foo'+' with '+[x])
    public function yFoo() trace('calling '+'yFoo'+' on '+'foo'+' with '+[])
    @:prop(fields.get('barVar'), fields.set('barVar', param)) var barVar:V;//see accessor generation
    public function doBar(a:A, b:B, c:C) trace('calling '+'doBar'+' on '+'bar'+' with '+[a, b, c])
}
```

This feature is quite exotic. It's intention is to allow building full proxies, such as `haxe.remoting.Proxy`.

## Delegation rules

- Forward is generated per member in order of appearance
- If a member with a given name already exists, no forward statement is generated (i.e. if `FooBar` already had a method `fooX` in the above statement, the forwarding method would not be generated). This applies also if the member is defined in a super class.

## Delegation on interfaces

Using this syntax on interfaces will cause sensible [partial implementations](#partial-implementation) most of the time. Consider it experimental.

