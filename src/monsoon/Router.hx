package monsoon;

import monsoon.Router.Params;
import monsoon.Router.Route;
import haxe.DynamicAccess;

using tink.CoreApi;
using StringTools;
using Lambda;

typedef Params = Null<Map<String, String>>;

typedef Route = {
	path: String,
	callback: Request -> Response -> Void
}

typedef RouteMatch = {
	route: Route,
	params: Params
}

typedef MatcherI = {
	public function new(): Void;
}

class Router {
	
	var routes: List<Route> = new List();
	var matcher: PathMatcher;

	public function new() {
		matcher = new PathMatcher();
	}
	
	public function route<T>(path: String, callback: Request<T> -> Response -> Void) {
		routes.add({path: path, callback: cast callback});
		return this;
	}
	
	public function findRoute(path: String): Pair<Route, Params> {
		var found = null;
		routes.map(function(route) {
			var match = matcher.matchRoute(path, route);
			if (match.a)
				found = new Pair(route, match.b);
		});
		return found;
	}
	
}