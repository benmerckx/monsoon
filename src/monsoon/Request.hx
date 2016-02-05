package monsoon;

import tink.core.Future;
import tink.http.Request.IncomingRequest;
import haxe.DynamicAccess;
import tink.http.KeyValue;

@:allow(monsoon.Monsoon)
class RequestAbstr<T> {
	
	public var params(default, null): T;
	var done(default, never) = Future.trigger();
	var request: IncomingRequest;
	
	public var url(get, never): String;
	inline function get_url(): String
		return request.header.uri;
	
	public var path(get, never): String;
	inline function get_path(): String 
		return url.split('?')[0];
	
	public var method(get, never): Method;
	inline function get_method(): Method 
		return (request.header.method: String).toLowerCase();
	
	public var hostname(get, never): Null<String>;
	function get_hostname(): Null<String>{
		// todo: check X-Forwarded-For
		var headers = request.header.get('host');
		if (headers.length > 0) 
			return (headers[0]: String).split(':')[0];
		return null;
	}
	
	public var ip(get, never): String;
	inline function get_ip(): String return request.clientIp;
	
	public var query(get, never): Map<String, String>;
	function get_query()
		return [
			for (p in KeyValue.parse(url.indexOf('?') > -1 ? url.split('?')[1] : ''))
				p.a => (p.b == null ? null : StringTools.urlDecode(p.b))
		];
	
	public function new(request: IncomingRequest)
		this.request = request;
	
	public function next()
		done.trigger(null);
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}