package monsoon;

import tink.http.Request;
import tink.http.Response;
import tink.http.Handler;
import tink.core.Future;
import haxe.Constraints.Function;

typedef LayerBase = IncomingRequest -> HandlerFunction -> Future<OutgoingResponse>;

@:callable
abstract Layer(LayerBase) from LayerBase to Function {
	
	inline function new(func) 
		this = func;
	
	@:from
	public inline static function fromMiddleware(middleware: Handler -> Handler)
		return new Layer(function(req, next)
			return middleware(function(req)
				return next(req)
			).process(req)
		);
	
	@:from
	public inline static function fromHandler(func: Handler)
		return new Layer(function(req, next) return func.process(req));
		
}