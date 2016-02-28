package monsoon;

import tink.http.Container;
import tink.http.Header.HeaderField;
import tink.http.Request;
import tink.http.Response;
import tink.core.Future;
import sys.FileSystem;
import monsoon.Request;
import monsoon.Response;
import monsoon.PathMatcher;
import monsoon.Router;
import haxe.CallStack;
using tink.CoreApi;

typedef AppOptions = {
	?watch: Bool, ?threads: Int
}

class Monsoon {
	var options: AppOptions = {
		watch: false,
		threads: 64
	};
	var routers: List<{router: Router<Any>, ?prefix: String}> = new List();
	public var router(default, null): Router<Path>;

	public function new(?options: AppOptions) {
		if (options != null)
			for (key in Reflect.fields(options))
				Reflect.setField(this.options, key, Reflect.field(options, key));
		routers.add({router: cast router = new Router<Path>(new PathMatcher())});
	}
		
	function serve(incoming: IncomingRequest) {
		var trigger = Future.trigger();
		var request = new Request(incoming);
		var response = new Response();
		next(request, response, 0);
		return response.done.asFuture();
	}
	
	function next(request: Request, response: Response, index: Int) {
		var path: String = Path.format(request.path);
		for (item in routers) {
			var router = item.router;
			/*if (item.prefix != null) {
				if (path.substr(0, item.prefix.length) != item.prefix)
					continue;
			}*/
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
							var inst: Middleware = item.create();
							mw.push(inst);
							inst.process(request, response);
							inst.done.asFuture().handle(function(_) processNext(middleware));
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
					request.done.asFuture().handle(function(_) {
						request.done = Future.trigger();
						next(request, response, route.order);
					});
					return;
				default:
			}
		}
		response.done.trigger(error(
			404, 'Not found', '404'
		));
	}
	
	function error(code, title, data)
		return new OutgoingResponse(
			new ResponseHeader(
				code, title, [new HeaderField('Content-Type', 'text/plain; charset=utf-8')]
			), 
			data
		);
	
	public function use(?prefix: String, router: Router<Dynamic>) {
		routers.add({router: cast router, prefix: prefix == null ? null : Path.format(prefix)});
	}
	
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
			if (e.indexOf('socket_bind') > -1)
				throw "Could not bind on port "+port;
			throw e;
		}
		
		#if (embed && neko) if (options.watch) watch(); #end
	}
	
	#if embed
	function loop() {
		var mutex = new tink.concurrent.Mutex();
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