package monsoon;

import tink.http.Container;
import tink.http.Request;
import tink.http.Response;
import tink.core.Future;
import sys.FileSystem;
import monsoon.Request;
import monsoon.Response;
using tink.CoreApi;

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
	var routers: List<Router<Any>> = new List();

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
		
	function serve(incoming: IncomingRequest) {
		var request = new Request(incoming);
		for (router in routers) {
			switch(router.findRoute(request)) {
				case Success(match):
					var route = match.a;
					request.setParams(match.b);
					var response = new Response();
					route.callback(request, response);
					return response.done.asFuture();
				default:
			}
		}
		return Future.sync(('404': OutgoingResponse)); 
	}
	
	public function use(router: Router<Dynamic>)
		routers.add(router);
	
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