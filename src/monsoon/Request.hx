package monsoon;

import tink.http.Request.IncomingRequest;

class MonsoonRequest<T> {
	
	public var params(default, null): T;
	var request: IncomingRequest;
	
	public function new(request: IncomingRequest, ?params: Map<String, String>) {
		this.request = request;
		if (params != null) {
			var paramObject = {};
			for (param in params.keys()) {
				Reflect.setField(paramObject, param, params.get(param));
			}
			this.params = cast paramObject;
		}
	}
	
}

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}