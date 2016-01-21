package;

typedef ContainerMode = monsoon.App.ContainerMode;
typedef Response = monsoon.Response;
typedef App = monsoon.App;
typedef Router<P> = monsoon.Router<P>;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}

class RouteHelper {
	macro public static function route<A, B>(router: haxe.macro.Expr.ExprOf<Router<A>>, path: haxe.macro.Expr, callback: haxe.macro.Expr) {
		return macro return router.addRoute($path, $callback);
	}
}