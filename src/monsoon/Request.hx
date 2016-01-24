package monsoon;

import tink.http.Request.IncomingRequest;

class Request<T> {
	
	public var params(default, null): T;
	var request: IncomingRequest;
	
	public var uri(get, never): String;
	inline function get_uri(): String return request.header.uri;
	
	public var method(get, never): Method;
	inline function get_method(): Method return (request.header.method: String).toLowerCase();
	
	public function new(request: IncomingRequest)
		this.request = request;
	
	@:allow(monsoon.App)
	function setParams(params: T)
		this.params = params;
}