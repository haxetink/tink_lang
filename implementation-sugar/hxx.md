# HXX

To make writing [HXX](https://github.com/haxetink/tink_hxx) a little easier, `tink_lang` will interpret `@hxx $someExpr` as  `hxx($someExpr)` and furthermore modify function bodies that are nothing but a string constant to `return hxx(<theString>)`. With Haxe 4, it will also pass inline markup literals to whatever `hxx` function is in scope.

This means that the following four are equivalent:

```haxe
function render() '
  <div>Hello, world!</div>
';

function render() 
  return @hxx'
    <div>Hello, world!</div>
  ';

function render()
  return hxx('
    <div>Hello, world!</div>  
  ');
  
// in haxe 4
function render() 
  return <div>Hello, world!</div>;  
```
