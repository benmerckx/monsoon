package monsoon.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ComplexTypeTools;
import haxe.macro.TypeTools;
import haxe.macro.Type;
import tink.core.Outcome;

#if !macro
import monsoon.Router;
import monsoon.Monsoon;
#end

typedef Arg = {
	name: String,
	t: Type
}

class AppHelper {
	macro public static function route<A, B>(app: ExprOf<Monsoon>, path: Expr, callback: Expr)
		return RouteHelper.addRoute(macro $app.router, path, callback);
}

class RouteHelper {
	
	macro public static function route<A, B>(router: ExprOf<Router<A>>, path: Expr, callback: Expr)
		return RouteHelper.addRoute(router, path, callback);
	
	#if macro
	
	public static function addRoute<A, B>(router: Expr, path: Expr, callback: Expr) {
		var type = Context.typeExpr(callback),
			args: Array<Arg>,
			state = ComplexType.TAnonymous([]),
			middleware = [];
			
		switch argsFromTypedExpr(type) {
			case Success(a): args = a;
			case Failure(e): Context.error(e, callback.pos);
		}
		
		if (args.length < 2) 
			Context.error('2 or more arguments expected', callback.pos);
		var request = args.shift();
		switch request.t {
			case TInst(t, params): 
				if (Std.string(t) != 'monsoon.RequestAbstr') 
					Context.error('Type Request expected for argument '+request.name, callback.pos);
				state = TypeTools.toComplexType(Context.follow(params[0]));
			default:
		}
		var params = [];
		switch (state) {
			case ComplexType.TAnonymous(fields):
				params = fields.map(fieldInfo);
			default:
				Context.error('Request type parameter must be TAnonymous', callback.pos);
		}
		
		var response = args.shift();
		
		var calls: Array<Expr> = [macro @:pos(callback.pos) cast request, macro @:pos(callback.pos) response];
		
		// middleware
		if (args.length > 0) {
			middleware = args.map(function(arg) {
				var type = TypeTools.toComplexType(Context.follow(arg.t));
				return switch type {
					case TPath(path): macro {
						name: $v{arg.name},
						create: function() return new $path()
					};
					default:
						Context.error('TPath expected for middleware type', callback.pos);
				} 
			});
			for (i in 0 ... args.length)
				calls.push(macro @:pos(callback.pos) cast middleware[$v{i}]);
		}
		
		return macro $router.addRoute({
			path: $path, 
			invoke: function(request, response, middleware) {
				($callback)($a{calls});
			},
			types: $v{params},
			middleware: $a{middleware}
		});
	}
	
	static function argsFromTypedExpr(type: TypedExpr): Outcome<Array<Arg>, String>
		return switch type.expr {
			case TFunction(func):
				Success(argsFromTFunc(func));
			case TField(e, a):
				switch type.t {
					case TFun(a, _): Success(a);
					default: 
						Failure('Callback must be a function');
				}
			default:
				Failure('Callback must be a function');
		}
		
	static function argsFromTFunc(f: TFunc): Array<Arg>
		return f.args.map(function(arg) return {name: arg.v.name, t: arg.v.t});
	
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