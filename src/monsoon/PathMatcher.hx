package monsoon;

import haxe.DynamicAccess;

using tink.CoreApi;
using Lambda;
using StringTools;
using haxe.EnumTools.EnumValueTools;

enum MethodPath {
	All(path: String);
	Delete(path: String);
	Get(path: String);
	Head(path: String);
	Options(path: String);
	Patch(path: String);
	Post(path: String);
	Put(path: String);
}

@:forward
abstract Path(PathAbstr) {
	
	public static inline var IDENTIFIER = ':';
	
	public inline function new(path, method)
		this = new PathAbstr(path, method);
	
	@:from
	static public function fromString(s:String) 
		return (MethodPath.All(s): Path);
		
	@:from
	static public function fromMethod(method: MethodPath)
		return new Path(method.getParameters()[0], method.getName().toLowerCase());
		
}

class PathAbstr {
	
	public var path(default, null): String;
	public var method(default, null): Method;
	
	public function new(path, method) {
		this.path = path;
		this.method = method;
	}
	
}

class PathMatcher implements Matcher<Path> {

	public function new() {}
	
	public function match(request: Request<Dynamic>, input: Path, types: Array<ParamType>): Outcome<Dynamic, Noise> {
		if (input.method != 'all' && request.method != input.method) 
			return Failure(Noise);
		var path = format(input.path);
		var uri = format(request.path);
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
	
	function format(path: String) {
		path = path.replace('//', '/');
		if (path.charAt(0) == '/') 
			path = path.substr(1);
		if (path.charAt(path.length-1) == '/') 
			path = path.substr(0, path.length-1);
		return path;
	}
	
	function filter(value: String, type: String): Outcome<Dynamic, Noise>
		return switch (type) {
			case 'Int':
				var nr = Std.parseInt(value);
				if (nr == null) Failure(Noise);
				else if (Std.string(nr) != value) Failure(Noise);
				else Success(nr);
			case 'Float':
				var nr = Std.parseFloat(value);
				if (nr == null) Failure(Noise);
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