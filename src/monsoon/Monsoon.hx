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
		var request = new Request(incoming),
			response = new Response(),
			trigger = Future.trigger();
		
		router.passThrough(request, response).handle(function(success) {
			if (!success)
				response.error(404, '404 Not found');
		});
		
		response.done.asFuture().handle(function(_) {
			trigger.trigger(response.tinkResponse());
		});
		
		return trigger.asFuture();
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
	
	#if display
	public function route<P>(path: P, callback: Request -> Response -> Void) {}
	#end
}