package monsoon;

import haxe.DynamicAccess;
import monsoon.PathMatcher;
import haxe.Constraints.Function;

using tink.CoreApi;

typedef MiddlewareItem = {
	name: String,
	create: Void -> Dynamic
}

typedef Route<P> = {
	path: P,
	//callback: Function, //Request -> Response -> Void,
	invoke: Request -> Response -> Array<Middleware> -> Void,
	types: Array<ParamType>,
	middleware: Array<MiddlewareItem>,
	?order: Int
}

class Router<P> {
	
	static var index: Int = 0;
	var routes: List<Route<P>> = new List();
	var matcher: Matcher<P>;
 
	public function new(?matcher: Matcher<P>) {
		this.matcher = matcher;
	}
	
	public function addRoute<T>(route: Route<P>) {
		route.order = ++index;
		routes.add(route);
		return this;
	}
	
	public function findRoute(request: Request, index: Int): Outcome<Pair<Route<P>, Any>, Noise> {
		for (route in routes) {
			if (route.order <= index) continue;
			switch (matcher.match(request, route.path, route.types)) {
				case Success(params): return Success(new Pair(route, params));
				default:
			}
		}
		return Failure(Noise);
	}
	
}