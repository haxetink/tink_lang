package tink.lang.macros;

import haxe.macro.Expr;

typedef CustomIter = {
	init: Array<Expr>,
	hasNext: Expr,
	next: Expr
}