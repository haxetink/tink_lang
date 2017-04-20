# Notifiers

To make defining signals and futures (and usually the associated triggers) easy, you can use the following syntax:

```haxe
@:tink class Observable {
    @:signal var click:MouseEvent;
    @:future var data:Bytes;
    @:signal var clickLeft = this.click.filter(function (e:MouseEvent) return e.x < this.width / 2);
    @:future var jsonData = this.data.map(function (b:Bytes) return b.toString()).map(haxe.Json.parse);
}
```

This will be converted as follows:

```haxe
@:tink class Observable {
    private var _click:SignalTrigger<MouseEvent>;
    private var _data:FutureTrigger<Bytes>;
    @:readonly var click:Signal<MouseEvent> = _click.toSignal();
    @:readonly var data:Future<Bytes> = _data.toFuture();
    @:readonly var clickLeft = this.click.filter(function (e) e.x < this.width / 2);
    @:readonly var jsonData = this.data.map(function (b) return b.toString()).map(haxe.Json.parse);
}
```

As we see, not specifying an initialization will cause generation of a trigger. If you do specify an initialization, you might just as well use normal property notation. This syntax however allows for a consistent notation in both cases, that allows users to see signals and futures at a single glance.

## Signal/Future on interfaces

You can use this syntax on interfaces also, which causes [partial implementations](#partial-implementation). If a trigger is generated, it will get a `@:usedOnlyBy`-clause.

