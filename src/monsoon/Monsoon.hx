package monsoon;

import tink.http.Container;
import tink.http.Header.HeaderField;
import tink.http.Request;
import tink.http.Response;
import tink.core.Future;
import sys.FileSystem;
import monsoon.Request;
import monsoon.Response;
import monsoon.Router;
import haxe.CallStack;
using tink.CoreApi;

typedef AppOptions = {
	?watch: Bool, ?threads: Int
}

class Monsoon {
	
	public var router(default, null): Router = new Router();
	var options: AppOptions = {
		watch: false,
		threads: 64
	};

	public function new(?options: AppOptions) {
		if (options != null)
			for (key in Reflect.fields(options))
				Reflect.setField(this.options, key, Reflect.field(options, key));
	}
		
	function serve(incoming: IncomingRequest) {
		var trigger = Future.trigger(),
			request = new Request(incoming),
			response = new Response();
		
		passThroughRouter(router, request, response).handle(function(success) {
			if (!success)
				notFound(request, response);
		});
		
		return response.done.asFuture();
	}
	
	function notFound(request: Request, response: Response) {
		response.done.trigger(error(
			404, 'Not found', '404 request: '+Std.string(request)
		));
	}
	
	function passThroughRouter(router: Router, request: Request, response: Response): Future<Bool> {
		var trigger = Future.trigger();
		
		function done(_) {
			trigger.trigger(true);
		}
		
		function pass(next, route, _) {
			request.done = Future.trigger();
			next(router, request, response, route.order);
		}
		
		function next(router, request, response, index) {
			switch handleRoute(router, request, response, index) {
				case Success(route):
					request.done.asFuture().handle(pass.bind(next, route));
					response.done.asFuture().handle(done);
				default:
					trigger.trigger(false);
			}
		}
		
		next(router, request, response, 0);
		
		return trigger.asFuture();
	}
	
	function handleRoute(router: Router, request: Request, response: Response, index: Int): Outcome<Route<Any>, Noise>
		switch router.findRoute(request, index) {
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
						var mwRouter = new Router(router);
						var inst: Middleware = item.create(mwRouter);
						mw.push(inst);
						passThroughRouter(mwRouter, request, response).handle(function(success) {
							if (!success)
								processNext(middleware);
						});
					}
					
					processNext(middleware);
				} catch (e: Dynamic) {
					var stack = CallStack.exceptionStack();
					response.done.trigger(error(
						500, 'Internal server error',
						'Uncaught exception: ' + Std.string(e) + "\n" +
						CallStack.toString(stack)
					));
				}
				return Success(route);
			default:
				return Failure(Noise);
		}
	
	function error(code, title, data)
		return new OutgoingResponse(
			new ResponseHeader(
				code, title, [new HeaderField('Content-Type', 'text/plain; charset=utf-8')]
			), 
			data
		);
	
	public function listen(port: Int = 80) {
		var container =
			#if embed
				new TcpContainer(port)
			#elseif  (neko || php)
				CgiContainer.instance
			#elseif js
				new NodeContainer(port)
			#else
				#error
			#end
		;
		
		try {
			container.run({
				serve: #if embed loop() #else serve #end,
				onError: function(e) trace(e),
				done: Future.trigger()
			});
		} catch (e: String) {
			if (e.indexOf('socket_bind') > -1 || e.indexOf('bind failed') > -1)
				throw "Could not bind on port "+port;
			throw e;
		}
		
		#if (embed && neko) if (options.watch) watch(); #end
	}
	
	#if embed
	function loop() {
		var queue = new tink.concurrent.Queue<Pair<IncomingRequest, Callback<OutgoingResponse>>>();
		for (i in 0 ... options.threads) {
			new tink.concurrent.Thread(function () 
				while (true) {
					var req = queue.await();
					serve(req.a).handle(function(response){
						req.b.invoke(response);
					});
				}
			);
		}
		return function (incoming) { 
			var trigger = Future.trigger();
			queue.push(new Pair(incoming, function (res) tink.RunLoop.current.work(function () trigger.trigger(res))));
			return trigger.asFuture();
		}
	}
	
	#if neko
	function watch() {
		new tink.concurrent.Thread(function () {
			var file = neko.vm.Module.local().name;
			
			function stamp() return 
				try FileSystem.stat(file).mtime.getTime()
				catch (e:Dynamic) Math.NaN;
				
			var initial = stamp();
			
			while (true) {
				Sys.sleep(.1);
				if (stamp() > initial)
					Sys.exit(0);
			}
		});
		
	}
	#end
	
	#end
}