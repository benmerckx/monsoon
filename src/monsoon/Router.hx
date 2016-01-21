package monsoon;

import haxe.DynamicAccess;

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
	
	public function route<T>(path: P, callback: Request<T> -> Response -> Void) {
		routes.add({path: path, callback: cast callback});
		return this;
	}
	
	public function findRoute(request: Request): Pair<Route<P>, Dynamic> {
		for (route in routes) {
			switch (matcher.matchRoute(request, route.path)) {
				case Success(params): return new Pair(route, params);
				default:
			}
		}
		return null;
	}
	
}