package monsoon;

import haxe.DynamicAccess;
import tink.http.Request.IncomingRequest;
import tink.Url;
using tink.CoreApi;

class MiddlewareCollection {
	var collection: Array<Middleware>;
	
	@:generic
	public function get<T: Middleware>(type: Class<T>): T {
		for (mw in collection) {
			if (Std.is(mw, type)) {
				return cast mw;
			}
		}
		return null;
	}
	
	public function set<T: Middleware>(instance: T): T {
		collection.push(instance);
		return instance;
	}
}

@:keep
@:allow(monsoon.Router)
class RequestAbstr<T> {
	
	public var params(default, null): T;
	public var done(default, null) = Future.trigger();
	var request: IncomingRequest;
	
	public var url(default, null): Url;
	
	public var path(get, never): String;
	inline function get_path(): String 
		return url.path;
	
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
	function get_query(): Map<String, String> 
		return url.query.toMap();
	
	public var middleware(default, null): DynamicAccess<Middleware>;
	
	public function new(request: IncomingRequest) {
		this.request = request;
		this.url = request.header.uri;
	}
	
	public function next()
		done.trigger(Noise);
		
	public function toString() return Std.string({
		method: method, url: url, path: path,
		ip: ip, hostname: hostname, query: query,
		params: params
	});
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}