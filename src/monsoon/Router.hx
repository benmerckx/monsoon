package monsoon;

import haxe.DynamicAccess;
import monsoon.PathMatcher;
import monsoon.Matcher;
import haxe.Constraints.Function;
import haxe.CallStack;

using tink.CoreApi;

typedef MiddlewareItem = {
	name: String,
	create: Router -> Dynamic
}

typedef Route<P> = {
	path: P,
	invoke: Request -> Response -> Array<Middleware> -> Void,
	types: Array<ParamType>,
	middleware: Array<MiddlewareItem>,
	matcher: Matcher<P>,
	isMiddleware: Bool,
	?order: Int
}

class Router {
	
	public static var DEFAULT_MATCHER(default, null) = new PathMatcher();
	public var parent(default, null): Router;
	var prefix: Any;
	var routes: List<Route<Any>> = new List();
	var index = 0;
 
	public function new(?parent: Router, ?prefix: Any) {
		this.parent = parent;
		this.prefix = prefix;
	}
	
	public function addRoute<P>(route: Route<P>) {
		route.order = ++index;
		routes.add(cast route);
		return this;
	}
	
	public function findRoute<P>(request: Request, index: Int): Outcome<Pair<Route<P>, Any>, Noise> {
		for (route in routes) {
			if (route.order <= index) continue;
			var prefixes: Array<Any> = [prefix], p = parent;
			while (p != null) {
				prefixes.push(p.prefix);
				p = p.parent;
			}
			switch route.matcher.match(prefixes, request, route.path, route.types, route.isMiddleware) {
				case Success(params): 
					return Success(new Pair(cast route, params));
				default:
			}
		}
		return Failure(Noise);
	}
	
	public function passThrough(request: Request, response: Response): Future<Bool> {
		var trigger = Future.trigger();
		
		function done(_) {
			trigger.trigger(true);
		}
		
		function pass(next, route, _) {
			request.done = Future.trigger();
			next(request, response, route.order);
		}
		
		function next(request, response, index) {
			switch handleRoute(request, response, index) {
				case Success(route):
					request.done.asFuture().handle(pass.bind(next, route));
					response.done.asFuture().handle(done);
				default:
					trigger.trigger(false);
			}
		}
		
		next(request, response, 0);
		
		return trigger.asFuture();
	}
	
	function handleRoute(request: Request, response: Response, index: Int): Outcome<Route<Any>, Noise>
		switch findRoute(request, index) {
			case Success(match):
				var route = match.a;
				request.params = match.b;
				try {
					var iter = route.middleware.iterator(),
						mw = [];
						
					function processNext(cb) {
						if (iter.hasNext())
							cb(iter.next());
						else
							route.invoke(request, response, mw);
					}
					
					function middleware(item: MiddlewareItem) {
						var mwRouter = new Router(this);
						var inst: Middleware = item.create(mwRouter);
						if (Std.is(inst, monsoon.middleware.Route)) {
							var info: monsoon.middleware.Route<Dynamic> = cast inst;
							info.path = route.path;
							info.types = route.types;
							info.order = route.order;
							info.middleware = route.middleware;
							info.matcher = route.matcher;
							mw.push(inst);
							processNext(middleware);
							return;
						}
						mw.push(inst);
						mwRouter.passThrough(request, response).handle(function(success) {
							if (!success)
								processNext(middleware);
						});
					}
					
					processNext(middleware);
				} catch (e: Dynamic) {
					var stack = CallStack.exceptionStack();
					response.clear().status(500).send(
						'Internal server error\n\n' +
						'Uncaught exception: ' + Std.string(e) + "\n" +
						CallStack.toString(stack)
					);
				}
				return Success(route);
			default:
				return Failure(Noise);
		}
	
	#if display
	public function route<P>(path: P, callback: Request -> Response -> Void) {}
	#end
}