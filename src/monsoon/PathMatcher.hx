package monsoon;

import haxe.DynamicAccess;

using tink.CoreApi;
using Lambda;
using StringTools;

@:forward
abstract Path(String) {
	
	public static inline var IDENTIFIER = ':';
	
	public function new(path: String) {
		path = path.replace('//', '/');
		if (path.charAt(0) == '/') 
			path = path.substr(1);
		if (path.charAt(path.length-1) == '/') 
			path = path.substr(0, path.length-1);
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
	
	public function match(request: Request<Dynamic>, path: Path, types: Array<ParamType>): Outcome<Dynamic, Noise> {
		var uri: Path = request.uri;
		if (path == '*') 
			return Success(null);
		if (path.indexOf(':') == -1) {
			if (uri == path) 
				return Success(null);
			return Failure(Noise);
		}
		var pathSegments = path.split('/');
		var uriSegments = uri.split('/');
		if (pathSegments.length != uriSegments.length)
			return Failure(Noise);
		var i = 0;
		var params: DynamicAccess<Dynamic> = {};
		for (segment in uriSegments) {
			if (pathSegments[i].charAt(0) == Path.IDENTIFIER) {
				var name = pathSegments[i].substr(1), 
					value = segment,
					type = types.find(function(type) return type.name == name);
				trace(type);
				if (type != null) {
					switch (filter(value, type.type)) {
						case Success(v): params.set(name, v);
						default: return Failure(Noise);
					}
				}
				continue;
			}
			if (segment != pathSegments[i]) return Failure(Noise);
			i++;
		}
		return Success(params);
	}
	
	function filter(value: String, type: String): Outcome<Dynamic, Noise>
		return switch (type) {
			case 'Int':
				var nr = Std.parseInt(value);
				if (nr == null) Failure(Noise);
				else Success(nr);
			case 'String':
				Success(value);
			default: 
				Failure(Noise);
		}
	
}