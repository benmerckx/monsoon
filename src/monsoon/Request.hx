package monsoon;

import haxe.DynamicAccess;
import tink.http.Request.IncomingRequest;
import tink.Url;
using tink.CoreApi;

/*class MiddlewareCollection {
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
}*/

@:keep
@:allow(monsoon.Router)
@:allow(monsoon.PathMatcher)
class RequestAbstr<T> {
	
	public var params(default, null): T;
	public var done(default, null) = Future.trigger();
	var request: IncomingRequest;
	
	public var url(default, null): Url;
	
	public var path(default, null): String;
	
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
		
	public function get(name: String): Null<String> {
		// todo: remove this next tink_http update
		#if php
		name = name.split('-').join('_');
		#end
		var found = request.header.get(name);
		return found.length > 0 ? found[0] : null;
	}
	
	//public var middleware(default, null): DynamicAccess<Middleware>;
	public var cookies: Map<String, String> = new Map();
	
	public function new(request: IncomingRequest) {
		this.request = request;
		this.url = request.header.uri;
		//path = url.path;
		// https://github.com/HaxeFoundation/haxe/pull/5270
		for(header in request.header.get(#if php 'set_cookie' #else 'set-cookie' #end)) {
			var line = (header: String).split(';')[0].split('=');
			cookies.set(StringTools.urlDecode(line[0]), (line.length > 1 ? StringTools.urlDecode(line[1]) : null));
		}
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