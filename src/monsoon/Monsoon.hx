package monsoon;

import tink.http.Container;
import tink.http.Request;
import tink.http.Response;
import tink.core.Future;
import sys.FileSystem;
import monsoon.Request;
import monsoon.Response;
import monsoon.PathMatcher;
using tink.CoreApi;

typedef AppOptions = {
	?watch: Bool, ?threads: Int
}

class Monsoon {
	var options: AppOptions = {
		watch: false,
		threads: 64
	};
	var routers: List<Router<Any>> = new List();
	public var router(default, null): Router<Path>;

	public function new(?options: AppOptions) {
		if (options != null)
			for (key in Reflect.fields(options))
				Reflect.setField(this.options, key, Reflect.field(options, key));
		routers.add(cast router = new Router<Path>(new PathMatcher()));
	}
		
	function serve(incoming: IncomingRequest) {
		var trigger = Future.trigger();
		next(incoming, 0, trigger);
		return trigger.asFuture();
	}
	
	function next(incoming: IncomingRequest, index: Int, trigger: FutureTrigger<OutgoingResponse>) {
		var request = new Request(incoming);
		for (router in routers) {
			switch router.findRoute(request, index) {
				case Success(match):
					var route = match.a;
					request.params = match.b;
					var response = new Response();
					response.done = trigger;
					route.callback(request, response);
					request.done.asFuture().handle(function(_) {
						next(incoming, route.order, trigger);
					});
					return;
				default:
			}
		}
		trigger.trigger(('404': OutgoingResponse));
	}
	
	public function use(router: Router<Any>)
		routers.add(cast router);
	
	public function listen(port: Int = 80) {
		var container =
			#if embed
				new TcpContainer(port)
			#elseif  (neko || php)
				CgiContainer.instance
			#elseif js
				new NodeContainer(port)
			#else
				null
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
		
		#if embed
		if (options.watch) watch();
		#end
	}
	
	#if embed
	function loop() {
		var mutex = new tink.concurrent.Mutex();
		var queue = new tink.concurrent.Queue<Pair<IncomingRequest, Callback<OutgoingResponse>>>();
		for (i in 0 ... options.threads) {
			new tink.concurrent.Thread(function () 
				while (true) {
					var req = queue.await();
					serve(req.a).handle(function(response) {
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
	#end
	
	function watch() {
		#if embed
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
		#end
	}
}