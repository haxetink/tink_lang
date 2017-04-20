# Trailing arguments

Because of Haxe's call syntax you can often find yourself in a situation where a closing `)` corresponds to something *high* up. Tink has a notation for trailing arguments to deal with that, which transforms `someFunc(...args) => lastArg` to `someFunc(...args, lastArg)` and `new SomeClass(...args) => lastArg` to `new SomeClass(...args, lastArg)`.

Example use cases:

```haxe
myButton.on('click') => function () {
    trace('click!');
    triggerSomeAction();
}

sys.db.Mysql.connect() => { 
  host : "localhost",
  port : 3306,
  user : "root",
  pass : "",
  socket : null,
  database : "MyBase"
};
```
