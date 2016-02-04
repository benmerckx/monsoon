package monsoon;

import haxe.DynamicAccess;
import monsoon.PathMatcher;

using tink.CoreApi;

typedef Route<P> = {
	path: P,
	callback: Request -> Response -> Void,
	types: Array<ParamType>,
	order: Int
}

class Router<P> {
	
	static var index: Int = 0;
	var routes: List<Route<P>> = new List();
	var matcher: Matcher<P>;
 
	public function new(?matcher: Matcher<P>) {
		this.matcher = matcher;
	}
	
	public function addRoute<T>(path: P, callback: Request<T> -> Response -> Void, types: Array<ParamType>) {
		routes.add({path: path, callback: cast callback, types: types, order: ++index});
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