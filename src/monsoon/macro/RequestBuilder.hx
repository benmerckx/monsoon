package monsoon.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using Lambda;

class RequestBuilder {
	static var paramsType: Type;
	
	@:access(haxe.macro.TypeTools)
	static public function buildGeneric() {
		var state = (macro: {});
		paramsType = null;
		switch (Context.getLocalType()) {
			case TInst(cl, params):
				if (params.length == 1) {
					paramsType = params[0];
					state = TypeTools.toComplexType(params[0]);
				}
				if (params.length > 1) {
					Context.error("Too many type parameters, expected 0 or 1", Context.currentPos());
				}
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
	
	macro public static function getParamsType() {
		var test = '';
		trace(paramsType);
		if (paramsType != null) {
			switch (paramsType) {
				case TAnonymous(_.get() => def):
					for (field in def.fields) test += field.name;
				default:
			}
		}
		return macro $v{test};
	}
}