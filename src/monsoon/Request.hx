package monsoon;

import tink.http.Request;
import tink.Url;
import tink.http.Method;

using tink.CoreApi;

@:allow(monsoon.Monsoon)
class MonsoonRequest<T> extends IncomingRequest {
	
	public function new(req: IncomingRequest) {
		super(req.clientIp, req.header, req.body);
		path = header.uri.path;
		url = header.uri;
		query = cast url.query.toMap();
		method = header.method;
		for (header in header.get('set-cookie')) {
			var line = (header: String).split(';')[0].split('=');
			cookies.set(StringTools.urlDecode(line[0]), (line.length > 1 ? StringTools.urlDecode(line[1]) : null));
		}
	}
	
	public var params(default, null): T;
	public var path(default, null): String;
			
	public var url(default, null): Url;
	
	public var method(default, null): Method;
	
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
	
	public var query(default, null): Map<String, String> = new Map();
		
	public function get(name: String): Null<String> {
		var found = this.header.get(name);
		return found.length > 0 ? found[0] : null;
	}
	
	public var cookies(default, null): Map<String, String> = new Map();
	
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}