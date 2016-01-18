package monsoon;

import tink.http.Container;
import tink.http.Request;
import tink.http.Response;
import tink.core.Future;
import sys.FileSystem;
import monsoon.Request;
import monsoon.Response;

enum ContainerMode {
	Node;
	Cgi;
	Tcp;
}

typedef AppOptions = {
	?watch: Bool,
	?mode: ContainerMode
}

class App {
	var options: AppOptions;
	var router: Router = new Router();

	public function new(?options: AppOptions) {
		#if js
		options.mode = ContainerMode.Node;
		#end
		#if php
		options.mode = ContainerMode.Cgi;
		#end
		if (options.mode == null)
			throw "Set mode to continue";
		this.options = options;
	}
	
	public function route(path, callback)
		return router.route(path, callback);
		
	function serve(incoming: IncomingRequest) {
		var match = router.findRoute(incoming.header.uri);
		if (match != null) {
			var route = match.a, params = match.b;
			var request = new Request(incoming, params);
			var response = new Response();
			route.callback(request, response);
			return response.done.asFuture();
		} else {
			return Future.sync(('404': OutgoingResponse)); 
		}
	}
	
	public function listen(port: Int = 80) {
		var container = switch (options.mode) {
			#if neko
			case ContainerMode.Tcp:
				new TcpContainer(port);
			#end
			#if (neko || php)
			case ContainerMode.Cgi:
				CgiContainer.instance;
			#end
			#if js
			case ContainerMode.Node:
				new NodeContainer(port);
			#end
			default: throw "Mode not supported";
		}
		
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