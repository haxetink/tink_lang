# Partial implementation

Tink allows for partial implementations, that are quite similar to traits. Partial implementations are always declared as interfaces, that actually have an implementation. We'll take an example that might be familiar to Ruby programmers:

```haxe
@:tink interface Enumerable<T> {
    var length(get, never):Int;
    function get_length()
        return fold(0, function (count, _) return count + 1);
        
    function fold<A>(init:A, calc:A->T->A):A {
        forEach(function (v) init = calc(init, v));
        return init;
    }
    function forEach(f:T->Void):Void {
        for (v in this)
            f(v);
    }
    function map<A>(f:T->A):Array<A> {
        var ret = [];
        forEach(ret.push);
        return ret;
    }
    function filter<A>(f:T->Bool):Array<T> {
        var ret = [];
        forEach(function (v) if (f(v)) ret.push(v));
        return ret;
    }
}
```

The implementation will be "cut" and "pasted" into classes that implement the interface without providing their own implementation. It is important to understand this metaphor: The process happens at expression level and in some sense is quite similar to C++ templates. For example the implementation of `forEach` only requires that the final class be eligible as a for loop target. That can mean it's an Iterator, an Iterable or has a length and array access.

The partial implementation can basically refer to any identifier. They only need to exist in the final class scope. Please note that if the "pasted" expression leads to a type error, the final class is the best error position we can give. That is about the same quality as saying that the class does not implement a certain method required by one of its interfaces. Nonetheless, it can still be more misleading.

## On demand implementation

In some cases, you want to say "if you use this implementation, then also add member XYZ to build it on".

To extend the example above:

```haxe
@:tink interface Enumerable<T> {
    @:usedOnlyBy(iterator) var elements:Array<T>;
    function iterator():Iterator<T> {
        return elements.iterator();
    }
    /* see above for the rest */
}
```

Now what this means is, that *if* the iterator implementation is taken from `Enumerable`, then `elements` will be generated. More generally, it will be generated if *any* of the members listed in the `@:usedOnlyBy` metadata are taken from the partial implementation. Note that `elements` will *not* be part of the interface itself. 

Note that we can go further:

```haxe
@:tink interface Enumerable<T> {
    @:usedOnlyBy(iterator) 
    var elements:Array<T>;
    @:usedOnlyBy(forEach)
    public function iterator():Iterator<T> {
        return elements.iterator();
    }
    /* see above for the rest */
}
```

## Default initialization

The above is rather hard to use, if `elements` is not initialized. Therefore we also define a default value:

```haxe
@:tink interface Enumerable<T> {
    @:usedOnlyBy(iterator) 
    var elements:Array<T> = [];
    @:usedOnlyBy(forEach)
    function iterator():Iterator<T> {
        return elements.iterator();
    }
    /* see above for the rest */
}
```

Default initializations are added at the beginning of the final class constructor through [direct initialization](declaration-sugar/property-declaration.md#direct-initialization), if the corresponding field is generated. This doesn't require `@:usedOnlyBy`.

## Partial implementation caveats and use cases

This feature should be used sparsingly. Composition is preferable (check out [syntactic delegation](declaration-sugar/syntactic-delegation.md)). You would use partial implementation when:

1. Performance matters so badly, that you cannot afford the cost of composition. Beware of premature optimization here.
2. What you do is so simple, that composition would complicate it.
3. You have some intricate relationship that is hard, if not impossible, to express in the type system.

To expand on the second case:

```haxe
interface Identifiable {
    var id(default, null):Int = Id.generate();
}
```

Hence if you now implement `Identifiable`, the id variable will be added and initialized automatically.

To expand on the third case: Haxe's `@:generic` can work some wonders, but it cannot really cover everything. For example it demands for type parameters to be physical types (classes/interfaces or enums). Partial implementations don't have that restriction. Also, some constraints cannot be expressed with types, such as "can be iterated over" (which can be satisfied in many ways) or "supports array access" (which is true for `Array`, `ArrayAccess` and any abstract that defines array access) or "supports `+` operator".

One major trip wire is that `import` and `using` in the scope of the partial implementation will be ignored. This is not absolutely unsolvable, but a solution with the means currently provided by the macro API would be quite expensive.

To some extent, this is also an advantage of this feature. You may for example have implemented a `using` extension for some type, that gives it the same interface as some other type. Or you may have two abstracts, that have the same methods. But the Haxe type system does not allow for polymorphism in this case.

Say you have this:

```haxe
class ArrayMapExtension {
    static public function exists<A>(arr:Array<A>, key:Int):Bool
        return key > -1 && key < arr.length;
    static public function keys<A>(arr:Array<A>):Iterator<Int>
        return 0...arr.length;
}
```

If you were `using` this, then an array can easily act as a read-only map.

```haxe
interface PairMaker<K, V, T> {
    function make(target:T):Array<Pair<K, V>>
        return [for (i in target.keys()) new Pair(i, target[i])]
}

class IntMapPairMaker<V> implements PairMaker<Int, V, Map<Int, V>> {}

using ArrayMapExtension;

class ArrayPairMaker<V> implements PairMaker<Int, V, Array<V>> {}
```

Finally, it should be noted that like `@:generic`, partial implementations will cause generation of lots of code.

