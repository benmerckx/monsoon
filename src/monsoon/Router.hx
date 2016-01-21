package monsoon;

import haxe.DynamicAccess;
import monsoon.macro.RequestBuilder;
import monsoon.PathMatcher;

using tink.CoreApi;
using StringTools;
using Lambda;

typedef Route<P> = {
	path: P,
	callback: Request -> Response -> Void
}

typedef MatcherI = {
	public function new(): Void;
}

class Router<P> {
	
	var routes: List<Route<P>> = new List();
	var matcher: Matcher<P>;
 
	public function new(?matcher: Matcher<P>) {
		this.matcher = matcher;
	}
	
	public function addRoute<T>(path: P, callback: Request<T> -> Response -> Void) {
		routes.add({path: path, callback: cast callback});
	}
	
	public function findRoute(request: Request): Outcome<Pair<Route<P>, Dynamic>, Noise> {
		for (route in routes) 
			switch (matcher.matchRoute(request, route.path)) {
				case Success(params): return Success(new Pair(route, params));
				default:
			}
		return Failure(Noise);
	}
	
}