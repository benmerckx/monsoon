package monsoon;

import tink.http.Request.IncomingRequest;
import tink.http.KeyValue;
using tink.CoreApi;

@:allow(monsoon.Monsoon)
class RequestAbstr<T> {
	
	public var params(default, null): T;
	var done(default, null) = Future.trigger();
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
	
	public var body(default, null): Body;
	
	public function new(request: IncomingRequest) {
		this.request = request;
		this.body = new Body(request.body);
	}
	
	public function next()
		done.trigger(Noise);
		
	public function toString() return Std.string({
		method: method, url: url, path: path,
		ip: ip, hostname: hostname, query: query,
		params: params, body: body.toString()
	});
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}