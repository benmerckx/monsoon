package monsoon;

import haxe.DynamicAccess;
import monsoon.PathMatcher;

using tink.CoreApi;

typedef Route<P> = {
	path: P,
	callback: Request<Dynamic> -> Response -> Void,
	types: Array<ParamType>
}

class Router<P> {
	
	var routes: List<Route<P>> = new List();
	var matcher: Matcher<P>;
 
	public function new(?matcher: Matcher<P>) {
		this.matcher = matcher;
	}
	
	public function addRoute<T>(path: P, callback: Request<T> -> Response -> Void, types: Array<ParamType>) {
		routes.add({path: path, callback: cast callback, types: types});
		return this;
	}
	
	public function findRoute(request: Request<Dynamic>): Outcome<Pair<Route<P>, Dynamic>, Noise> {
		for (route in routes) 
			switch (matcher.match(request, route.path, route.types)) {
				case Success(params): return Success(new Pair(route, params));
				default:
			}
		return Failure(Noise);
	}
	
}