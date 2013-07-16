package tink.lang.macros;

import haxe.macro.Expr;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.MacroTools;
using haxe.macro.ExprTools;

class StackAlloc {

	static function getEscapers(e:Expr) {
		var escapers = new Hash();
		function esc(s) 
			escapers.set(s, true);
		function forceEscape(e:Expr) {}
			//e.iter(function (e:Expr) {
				//switch (e.getIdent()) {
					//case Success(s): esc(s);
					//default: e.iter(forceEscape);
				//}
			//});
			
		function escapeCalls(e:Expr)
			switch (e.expr) {
				case EBinop(OpAssign, e1, e2):
					forceEscape(e1);
					forceEscape(e2);
				case EArrayDecl(vals):
					vals.iter(forceEscape);
				case EObjectDecl(fields):
					for (f in fields)
						forceEscape(f.expr);
				case ECall(e, params):
					forceEscape(e);
					params.iter(forceEscape);
				case ENew(_, params):
					params.iter(forceEscape);
				default:
					e.iter(escapeCalls);
			}
		escapeCalls(e);
		return escapers;
	}
	static function optimize(e:Expr) {
		var escaped = getEscapers(e);
		function stackAlloc(e:Expr, vars:Hash<Hash<Expr>>) 
			return
				switch (e.expr) {
					case EField({ expr: EConst(CIdent(s)) }, field):
						if (vars.exists(s))
							vars.get(s).get(field);
						else
							e;
					
					default:
						e.map(stackAlloc.bind(_, vars));
				}
		//return e.log();
		return stackAlloc(e, new Hash());
	}
	static public function process(ctx:ClassBuildContext) {
		if (ctx.cls.isInterface) return;
		for (member in ctx.members)
			switch (member.getFunction()) {
				case Success(f):
					if (f.expr != null) {
						var old = f.expr;
						f.expr = f.expr.outerTransform(function (e:Expr) 
							return switch (e = macro @:privateAccess $e).typeof() {
								case Success(_): 
									optimize(e.log());
								case Failure(f): 
									f.pos.warning('could not optimize expression. Avoid untyped and module sub types.');
									old.pos.warning(e.toString());
									f.pos.warning(f.data);
									old;
							}
						);
					}
				default:
			}
	}
	
}