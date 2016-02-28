package monsoon.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using Lambda;

class RequestBuilder {	
	static public function buildGeneric() {
		var state = (macro: {});
		switch (Context.getLocalType()) {
			case TInst(cl, params):
				if (params.length == 1)
					state = TypeTools.toComplexType(Context.follow(params[0]));
				if (params.length > 1)
					Context.error("Too many type parameters, expected 0 or 1", Context.currentPos());
			default:
				Context.error("Type expected", Context.currentPos());
		}
		return ComplexType.TPath({
			sub: 'RequestAbstr',
			params: [TPType(state)],
			pack: ['monsoon'],
			name: 'Request'
		});
	}
}