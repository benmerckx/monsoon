package monsoon;

import haxe.DynamicAccess;
import monsoon.PathMatcher;
import haxe.Constraints.Function;

using tink.CoreApi;

typedef MiddlewareItem = {
	name: String,
	create: Router -> Dynamic
}

typedef Route<P> = {
	path: P,
	invoke: Request -> Response -> Array<Middleware> -> Void,
	types: Array<ParamType>,
	middleware: Array<MiddlewareItem>,
	matcher: Matcher<P>,
	?order: Int
}

class Router {
	
	public static var DEFAULT_MATCHER(default, null) = new PathMatcher();
	public var parent(default, null): Router;
	var routes: List<Route<Any>> = new List();
	var index = 0;
 
	public function new(?parent: Router)
		this.parent = parent;
	
	public function addRoute<P>(route: Route<P>) {
		route.order = ++index;
		routes.add(cast route);
		return this;
	}
	
	public function findRoute<P>(request: Request, index: Int): Outcome<Pair<Route<P>, Any>, Noise> {
		for (route in routes) {
			if (route.order <= index) continue;
			switch (route.matcher.match(request, route.path, route.types)) {
				case Success(params): return Success(new Pair(cast route, params));
				default:
			}
		}
		return Failure(Noise);
	}
	
}