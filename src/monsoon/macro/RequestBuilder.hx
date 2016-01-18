package monsoon.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using Lambda;

@:access(haxe.macro.TypeTools)
class RequestBuilder {
	static var params: Array<Type>;

	static public function buildGeneric() {
		var state = (macro: {});
		switch (Context.getLocalType()) {
			case TInst(cl, paramList):
				params = paramList;
				if (params.length > 0)
					state = TypeTools.toComplexType(params[0]);
			default:
				Context.error("Type expected", Context.currentPos());
		}
		return ComplexType.TPath({
			sub: 'MonsoonRequest',
			params: [TPType(state)],
			pack: ['monsoon'],
			name: 'Request'
		});
	}
}