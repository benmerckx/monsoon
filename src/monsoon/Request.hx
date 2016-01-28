package monsoon;

import tink.http.Request.IncomingRequest;

class RequestAbstr<T> {
	
	@:allow(monsoon.Monsoon)
	public var params(default, null): T;
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
	
	public function new(request: IncomingRequest)
		this.request = request;
		
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}