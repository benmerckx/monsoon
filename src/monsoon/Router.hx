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

class Router {
	
	var routes: List<Route> = new List();

	public function new() {}
	
	public function route<T>(path: String, callback: Request<T> -> Response -> Void) {
		routes.add({path: formatPath(path), callback: cast callback});
		return this;
	}
	
	public function findRoute(path: String): Pair<Route, Params> {
		var found = null;
		path = formatPath(path);
		routes.map(function(route) {
			var match = matchRoute(path, route);
			if (match.a)
				found = new Pair(route, match.b);
		});
		return found;
	}
	
	function matchRoute(path: String, route: Route): Pair<Bool, Params> {
		if (path == '*') 
			return new Pair(true, null);
		if (route.path.indexOf(':') == -1)
			return new Pair(route.path == path, null);
		var pathSegments = path.split('/');
		var routeSegments = route.path.split('/');
		if (pathSegments.length != routeSegments.length)
			return new Pair(false, null);
		var i = 0;
		var params: Params = new Params();
		for (segment in pathSegments) {
			if (routeSegments[i].charAt(0) == Path.IDENTIFIER) {
				params.set(routeSegments[i].substr(1), segment);
				continue;
			}
			if (segment != routeSegments[i]) return new Pair(false, null);
			i++;
		}
		return new Pair(true, params);
	}
	
	function formatPath(path: String) {
		path = path.replace('//', '/');
		if (path.charAt(0) == '/') path = path.substr(1);
		if (path.charAt(path.length-1) == '/') path = path.substr(0, path.length-1);
		return path;
	}
	
}