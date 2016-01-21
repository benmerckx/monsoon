package monsoon;

import haxe.DynamicAccess;
import monsoon.Router;

using tink.CoreApi;
using Lambda;
using StringTools;

@:forward
abstract Path(String) {
	public static inline var IDENTIFIER = ':';
	
	public function new(path: String) {
		path = path.replace('//', '/');
		if (path.charAt(0) == '/') path = path.substr(1);
		if (path.charAt(path.length-1) == '/') path = path.substr(0, path.length-1);
		this = path;
	}
	
	@:from
	static public function fromString(s:String) 
		return new Path(s);
	
	inline public function getParamNames()
		return this
		.split('/')
		.filter(function(segment) return segment.charAt(0) == IDENTIFIER)
		.map(function(segment) return segment.substr(1));
}

class PathMatcher implements Matcher<Path> {

	public function new() {}
	
	public function matchRoute(request: Request, path: Path) {
		var uri: Path = request.uri;
		if (path == '*') 
			return Success(null);
		if (path.indexOf(':') == -1) {
			if (uri == path) 
				return Success(null);
			return Failure(null);
		}
		var pathSegments = path.split('/');
		var uriSegments = uri.split('/');
		if (pathSegments.length != uriSegments.length)
			return Failure(null);
		var i = 0;
		var params: DynamicAccess<String> = {};
		for (segment in uriSegments) {
			if (pathSegments[i].charAt(0) == Path.IDENTIFIER) {
				params.set(pathSegments[i].substr(1), segment);
				continue;
			}
			if (segment != pathSegments[i]) return Failure(null);
			i++;
		}
		return Success(params);
	}
	
}