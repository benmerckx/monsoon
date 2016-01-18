package monsoon;

import monsoon.Router;

using tink.CoreApi;
using StringTools;
using Lambda;

class PathMatcher {

	public function new() {
		
	}
	
	public function matchRoute(path: String, route: Route): Pair<Bool, Map<String, String>> {
		if (path == '*') 
			return new Pair(true, null);
		if (route.path.indexOf(':') == -1)
			return new Pair(route.path == path, null);
		var pathSegments = path.split('/');
		var routeSegments = route.path.split('/');
		if (pathSegments.length != routeSegments.length)
			return new Pair(false, null);
		var i = 0;
		var params: Map<String, String> = new Map();
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