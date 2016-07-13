package monsoon;

import tink.http.Request;
import tink.Url;
import tink.http.Method;

using tink.CoreApi;

@:forward
abstract RequestHelper<T: IncomingRequest>(T) from T to T {
	
	public inline function new(req)
		this = req;
		
	public var url(get, never): Url;
	inline function get_url(): Url 
		return this.header.uri;
	
	public var method(get, never): Method;
	inline function get_method(): Method 
		return this.header.method;
	
	public var hostname(get, never): Null<String>;
	inline function get_hostname(): Null<String> {
		var headers = this.header.get('host');
		if (headers.length > 0) 
			return (headers[0]: String).split(':')[0];
		return null;
	}
	
	public var ip(get, never): String;
	inline function get_ip(): String 
		return this.clientIp;
	
	public var query(get, never): Map<String, String>;
	inline function get_query(): Map<String, String> 
		return url.query.toMap();
		
	public inline function get(name: String): Null<String> {
		var found = this.header.get(name);
		return found.length > 0 ? found[0] : null;
	}
	
	public inline function cookies(): Map<String, String> {
		var cookies = new Map();
		for(header in this.header.get('set-cookie')) {
			var line = (header: String).split(';')[0].split('=');
			cookies.set(StringTools.urlDecode(line[0]), (line.length > 1 ? StringTools.urlDecode(line[1]) : null));
		}
		return cookies;
	}
	
	public var path(get, never): String;
	inline function get_path(): String
		return Std.is(this, MatchedRequest) ? (cast this).path : this.header.uri.path;
	
}

class MatchedRequest<T> extends IncomingRequest {
	
	public var params(default, null): T;
	public var path(default, null): String;
	
	public function new(req: IncomingRequest, params: T, path: String) {
		super(req.clientIp, req.header, req.body);
		this.params = params;
		this.path = path;
	}
	
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}