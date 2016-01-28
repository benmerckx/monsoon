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
	?watch: Bool
}

class Monsoon {
	var options: AppOptions;
	var routers: List<Router<Any>> = new List();
	public var router(default, null): Router<Path>;

	public function new(?options: AppOptions) {
		this.options = options;
		routers.add(cast router = new Router<Path>(new PathMatcher()));
	}
		
	function serve(incoming: IncomingRequest) {
		var request = new Request(incoming);
		for (router in routers) {
			switch(router.findRoute(request)) {
				case Success(match):
					var route = match.a;
					request.params = match.b;
					var response = new Response();
					route.callback(request, response);
					return response.done.asFuture();
				default:
			}
		}
		return Future.sync(('404': OutgoingResponse)); 
	}
	
	public function use(router: Router<Any>)
		routers.add(cast router);
	
	public function listen(port: Int = 80) {
		var container =
			#if (neko && embed)
				new TcpContainer(port)
			#elseif  ((!embed && neko) || php)
				CgiContainer.instance
			#elseif js
				new NodeContainer(port)
			#else
				null
			#end
		;
		
		try {
			container.run({
				serve: serve,
				onError: function(e) trace(e),
				done: Future.trigger()
			});
		} catch (e: String) {
			if (e.indexOf('socket_bind') > -1)
				throw "Could not bind on port "+port;
			throw e;
		}
		
		#if !php
		if (options.watch != null && options.watch) {
			new tink.concurrent.Thread(function () {
				var file = neko.vm.Module.local().name;
				
				function stamp() return 
					try FileSystem.stat(file).mtime.getTime()
					catch (e:Dynamic) Math.NaN;
					
				var initial = stamp();
				
				while (true) {
					Sys.sleep(.1);
					if (stamp() > initial) {
						Sys.println('File $file recompiled. Shutting down server');
						Sys.exit(0);
					}
				}
			});
		}
		#end
		
		return this;
	}
}