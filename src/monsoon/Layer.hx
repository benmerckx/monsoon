package monsoon;

import monsoon.Layer.Out;
import tink.core.Any;
import tink.http.Request;
import tink.http.Response;
import tink.http.Handler;
import tink.core.Future;
import haxe.Constraints.Function;
import monsoon.Request;

typedef In = Request<Any>;
typedef Out = Response;

typedef LayerBase = In -> Out -> (Void -> Void) -> Void;
typedef Middleware = {function process(request: In, response: Out, next: Void -> Void): Void;}

@:callable
abstract Layer(LayerBase) from LayerBase to LayerBase {
	
	inline function new(func) 
		this = func;
	
	/*@:from
	public inline static function fromMiddleware(middleware: Handler -> Handler)
		return new Layer(
			function(req, res, next)
				return middleware(function(req) {
					next();
					return res.future();
				}).process(req)
		);
	
	
	@:from
	public inline static function fromHandler(func: Handler)
		return new Layer(function(req, next) return func.process(req));*/
	
	@:from
	public inline static function fromMW(mw: Middleware)
		return new Layer(mw.process);
		
	@:from
	public inline static function fromBasic(cb: In -> Out -> Void)
		return new Layer(
			function(req, res, next)
				return cb(req, res)
		);
		
	@:from
	public inline static function fromTypedBasic<T>(cb: Request<T> -> Out -> Void)
		return new Layer(fromBasic(cast cb));
		
	@:from
	public inline static function fromTyped<T>(cb: Request<T> -> Out -> (Void -> Void) -> Void)
		return new Layer(cast cb);
	
	@:to
	public function toHandler(): Handler
		return function(req) {
			var res = new Out();
			this(new In(req), res, function() {});
			return res.future;
		}
}