package monsoon.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

class RequestBuilder {	
	static public function buildGeneric() {
		switch (Context.getLocalType()) {
			case TInst(cl, params):
				if (params.length == 0)
					return (macro: monsoon.Request.MonsoonRequest<tink.core.Any>);
				if (params.length == 1)
					return ComplexType.TPath({
						sub: 'MonsoonRequest',
						params: [TPType(TypeTools.toComplexType(Context.follow(params[0])))],
						pack: ['monsoon'],
						name: 'Request'
					});
				if (params.length > 1)
					Context.error("Too many type parameters, expected 0 or 1", Context.currentPos());
			default:
				Context.error("Type expected", Context.currentPos());
		}
		return null;
	}
}