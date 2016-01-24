package monsoon.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ComplexTypeTools;
import haxe.macro.TypeTools;
import haxe.macro.Type;

#if !macro
import monsoon.Router;
import monsoon.App;
#end

class AppHelper {
	macro public static function route<A, B>(app: haxe.macro.Expr.ExprOf<App>, path: haxe.macro.Expr, callback: haxe.macro.Expr) {
		return RouteHelper.addRoute(macro $app.router, path, callback);
	}
}

class RouteHelper {
	
	macro public static function route<A, B>(router: haxe.macro.Expr.ExprOf<Router<A>>, path: haxe.macro.Expr, callback: haxe.macro.Expr) {
		return RouteHelper.addRoute(router, path, callback);
	}
	
	#if macro
	
	public static function addRoute<A, B>(router: haxe.macro.Expr, path: haxe.macro.Expr, callback: haxe.macro.Expr) {
		Context.typeExpr(callback);
		var state = RequestBuilder.state;
		var params = [];
		switch (state) {
			case TAnonymous(fields):
				params = fields.map(fieldInfo);
			default: 
				// Move this to request builder for proper position
				Context.error('Request type parameter must be TAnonymous', Context.currentPos());
		}
		return macro $router.addRoute($path, $callback, $v{params});
	}
	
	static function fieldInfo(field: Field)
		return {
			name: field.name,
			type: fieldType(field.kind)
		}
	
	static function fieldType(kind: FieldType)
		return switch(kind) {
			case FVar(t, _):
				switch (TypeTools.toComplexType(Context.follow(ComplexTypeTools.toType(t)))) {
					case TPath(path): 
						var segments = path.pack;
						if (path.name != 'StdTypes')
							segments.push(path.name);
						if (path.sub != null)
							segments.push(path.sub);
						segments.join('.');
					default: null;
				}
			default: 
				Context.error('Only var type allowed for Request params', Context.currentPos());
				null;
		}
	
	#end
	
}