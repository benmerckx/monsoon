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
typedef WithProcess = {function process(request: In, response: Out, next: Void -> Void): Void;}
typedef WithCreateRoutes = {function createRoutes(router: Monsoon): Void;}

@:callable
abstract Layer(LayerBase) from LayerBase to LayerBase {
	
	inline function new(func)
		this = func;
	
	@:from
	public inline static function fromMiddleware(middleware: Handler -> Handler)
		return new Layer(
			function(req, res, next)
				middleware(function(req) {
					next();
					return res.future;
				})
				.process(req)
				.handle(function(outgoing)
					@:privateAccess
					res.ofOutgoingResponse(outgoing).end()
				)
		);
		
	@:from
	public inline static function fromHandler(func: Handler)
		return new Layer(function(req, res, next)
			func.process(req).handle(function(outgoing)
				@:privateAccess
				res.ofOutgoingResponse(outgoing).end()
			)
		);
	
	@:from
	public inline static function fromCreateRoutes(cr: WithCreateRoutes) {
		var router = new Monsoon();
		cr.createRoutes(router);
		return router.toLayer();
	}
	
	@:from
	public inline static function fromProcess(mw: WithProcess)
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
		
	@:from
	public inline static function fromMap(map: Map<String, Layer>): Layer {
		var router = new Monsoon();
		for (path in map.keys())
			router.route(path, map.get(path));
		return router;
	}
	
	@:to
	public function toHandler(): Handler
		return function(req) {
			var res = new Out();
			this(new In(req), res, function()
				res.error(404, 'Not found')
			);
			return res.future;
		}
	
}