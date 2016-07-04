package monsoon;

import tink.http.Handler;
import tink.http.Response;
import tink.http.containers.*;

using tink.CoreApi;

typedef Collection = Array<IncomingRequest -> Handler -> Future<OutgoingResponse>>;

abstract Layer(Collection) {
	public inline function new()
		this = [];
}

/*
@:forward
abstract Layer(Handler) from Handler to Handler {
		
	//@:op(A + B)
	public inline function add(layer: Layer): Layer {
		var prev = this;
		return this = function (req)
			return prev.process(req).flatMap(function (res) return 
				if (res.header.statusCode != 404)
					Future.sync(res)
				else
					layer.process(req)
			);
	}
		
}*/