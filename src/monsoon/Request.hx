package monsoon;

import tink.http.Request.IncomingRequest;

class MonsoonRequest<T> {
	
	public var params(default, null): T;
	var request: IncomingRequest;
	
	public var uri(get, never): String;
	function get_uri(): String return request.header.uri;
	
	public function new(request: IncomingRequest)
		this.request = request;
	
	@:allow(monsoon.App)
	public function setParams(params: T)
		this.params = params;
	
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}