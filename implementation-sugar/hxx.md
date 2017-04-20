# HXX

To make writing [HXX](https://github.com/haxetink/tink_hxx) a little easier, `tink_lang` will interpret `@hxx <someExpr>` as to `hxx(<someExpr>)` and furthermore modify function bodies that are nothing but a string constant to `return hxx(<theString>)`.