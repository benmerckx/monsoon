package monsoon;

import haxe.DynamicAccess;
import haxe.io.Path;
import monsoon.Matcher;
import monsoon.Router.Route;

using tink.CoreApi;
using Lambda;
using StringTools;
using haxe.EnumTools.EnumValueTools;

@:forward
abstract Path(String) from String to String {
	
	public static inline var IDENTIFIER = ':';
	public static inline var ASTERISK = '*';
	
	public inline function new(path)
		this = path;
		
	public static function format(path: String) {
		path = path.replace('//', '/');
		if (path.charAt(0) == '/') 
			path = path.substr(1);
		if (path.charAt(path.length-1) == '/') 
			path = path.substr(0, path.length-1);
		return path;
	}
}

class PathMatcher implements Matcher<Path> {

	public function new() {}
	
	public function transformInput(input: Path): Path {
		return input;
	}
	
	public function match(prefix: Array<Any>, request: Request<Dynamic>, route: Route<Path>): Outcome<Dynamic, Noise> {			
		if (route.method != Method.All && request.method != route.method) 
			return Failure(Noise);
			
		var path = Path.format(route.path),
			uri = Path.format(request.url.path),
			types = route.types,
			pathPrefix = '';
			
		for (p in prefix)
			if (Std.is(p, String) && p != '*') // Todo: this should check for Path once different matchers are allowed
				pathPrefix = p + '/' + pathPrefix;
		path = pathPrefix + path;
		
		if (route.isMiddleware && path.substr(path.length-1) != Path.ASTERISK)
			path += '/'+Path.ASTERISK;
		
		path = Path.format(path);
					
		var pathSegments = path.split('/');
		var uriSegments = uri.split('/');
		
		// create regex - todo: cleanup
		var vars = [];
		var pattern = pathSegments.map(function(segment) {
			return switch segment.charAt(0) {
				case Path.IDENTIFIER:
					vars.push(segment.substr(1));
					"\\/([^\\\\/]+?)";
				case Path.ASTERISK:
					vars.push(segment.substr(1));
					"(?:\\/([^\\\\/]+?(?:\\/[^\\\\/]+?)*))?";
				default:
					"[]{}\\^$.|?+()".split('').map(function(special) {
						segment = segment.split(special).join("\\"+special);
					});
					"\\/"+segment;
			}
		}).join('');
		pattern = "^" + pattern + "(?:\\/(?=$))?$";
		var regex = new EReg(pattern, 'i');
		
		switch regex.match('/'+uri) {
			case true:
				var params: DynamicAccess<Dynamic> = {},
					i = 0;
				for (name in vars) {
					var value = regex.matched(i+1),
						type = types.find(function(type) return type.name == name);
					if (type != null && name != '') {
						switch (filter(value, type.type)) {
							case Success(v): 
								params.set(name, v);
							default: 
								return Failure(Noise);
						}
					}
					i++;
				}
				if (route.isMiddleware && vars.length > 0)
					request.path = regex.matched(vars.length);
				return Success(params);
			default:
				return Failure(Noise);
		}
	}
	
	function filter(value: String, type: String): Outcome<Dynamic, Noise>
		return switch (type) {
			case 'Int':
				var nr = Std.parseInt(value);
				if (Math.isNaN(nr)) Failure(Noise);
				else if (Std.string(nr) != value) Failure(Noise);
				else Success(nr);
			case 'Float':
				var nr = Std.parseFloat(value);
				if (Math.isNaN(nr)) Failure(Noise);
				else if (Std.string(nr) != value) Failure(Noise);
				else Success(nr);
			case 'Bool': 
				if (value == '0' || value == 'false') Success(false);
				if (value == '1' || value == 'true') Success(true);
				Failure(Noise);
			case 'String':
				Success(value);
			default: 
				Failure(Noise);
		}
	
}