package monsoon;

import tink.http.Request;
import tink.Url;
import tink.http.Method;

using tink.CoreApi;

@:forward
@:allow(monsoon.Monsoon)
class MonsoonRequest<T> extends IncomingRequest {
	
	public function new(req: IncomingRequest)
		super(req.clientIp, req.header, req.body);
	
	public var params(default, null): T;
	public var path(default, null): String;
			
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
	
	public var cookies(get, never): Map<String, String>;
	function get_cookies(): Map<String, String> {
		var cookies = new Map();
		for(header in this.header.get('set-cookie')) {
			var line = (header: String).split(';')[0].split('=');
			cookies.set(StringTools.urlDecode(line[0]), (line.length > 1 ? StringTools.urlDecode(line[1]) : null));
		}
		return cookies;
	}
	
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}