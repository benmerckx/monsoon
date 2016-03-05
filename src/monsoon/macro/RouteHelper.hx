package monsoon.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ComplexTypeTools;
import haxe.macro.TypeTools;
import haxe.macro.Type;
import tink.core.Outcome;
import haxe.Constraints.Function;

#if !macro
import monsoon.Router;
import monsoon.Monsoon;
import monsoon.Middleware;
#end

typedef Arg = {
	name: String,
	t: Type
}

class AppHelper {
	macro public static function route(app: ExprOf<Monsoon>, path: Expr, ?callback: Expr)
		return RouteHelper.addRoute(macro $app.router, path, callback);
}

class RouteHelper {
	
	macro public static function route<A, B>(router: ExprOf<Router>, path: Expr, ?callback: Expr)
		return RouteHelper.addRoute(router, path, callback);
	
	#if macro
	
	public static function addRoute<A, B>(router: Expr, path: Expr, callback: Expr): Expr {
		switch callback {
			case macro null:
				switch path.expr {
					case ExprDef.EArrayDecl(values):
						return macro $b{values.map(routeFromBinOp.bind(router))};
					default:
						callback = path;
						path = macro '*';
				}
			default:
		}
		var type = Context.typeExpr(callback),
			args: Array<Arg>,
			state = ComplexType.TAnonymous([]),
			middleware = [],
			isMiddleware = false;
			
		switch type.expr {
			// middleware/controller
			case TypedExprDef.TTypeExpr(module):
				switch module {
					case ModuleType.TClassDecl(_.get() => c):
						var middlewareType = {
							name: c.module == null ? c.name : c.module,
							pack: c.pack,
							params: c.params.map(function(param: TypeParameter) 
								return TPType(TypeTools.toComplexType(param.t))
							),
							sub: c.module == null ? null : c.name
						};
						callback = macro @:pos(callback.pos) function(req: Request, res: Response, info: monsoon.middleware.Route<tink.core.Any>) {
							var router = new monsoon.Router($router, info.path);
							new $middlewareType(router);
							router.passThrough(req, res).handle(function(success)
								if (!success) req.next()
							);
						};
						type = Context.typeExpr(callback);
						isMiddleware = true;
					default:
				}
			default:
		}
			
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
		
		// inject middleware
		if (args.length > 0) {
			middleware = args.map(function(arg) {
				var type = TypeTools.toComplexType(Context.follow(arg.t));
				return switch type {
					case TPath(path): macro {
						name: $v{arg.name},
						create: function(router) return new $path(router)
					};
					default:
						Context.error('TPath expected for middleware type', callback.pos);
				} 
			});
			for (i in 0 ... args.length)
				calls.push(macro @:pos(callback.pos) cast middleware[$v{i}]);
		}
		
		return macro $router.addRoute({
			path: monsoon.Router.DEFAULT_MATCHER.transformInput($path),
			invoke: function(request, response, middleware) {
				($callback)($a{calls});
			},
			types: $v{params},
			middleware: $a{middleware},
			matcher: monsoon.Router.DEFAULT_MATCHER,
			isMiddleware: $v{isMiddleware}
		});
	}
	
	static function routeFromBinOp(router: Expr, e: Expr)
		return switch e.expr {
			case ExprDef.EBinop(OpArrow, e1, e2):
				RouteHelper.addRoute(router, e1, e2);
			default: 
				Context.error('Routes must be defined with =>', e.pos);
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