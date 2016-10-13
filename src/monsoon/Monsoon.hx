package monsoon;

import haxe.DynamicAccess;
import tink.http.Container;
import tink.http.containers.*;
import tink.http.Request;
import tink.http.Response;
import tink.http.Handler;
import tink.http.Method;
import monsoon.Request;
import monsoon.Response;
import monsoon.Layer;
import path2ereg.Path2EReg;

using Lambda;
using tink.CoreApi;

@:forward
abstract Monsoon(List<Layer>) from List<Layer> {
	
	public inline function new()
		this = new List();
		
	public inline function add(layer: Layer): Monsoon {
		this.add(layer);
		return this;
	}
		
	public inline function get(?path: String, callback: Layer)
		return route(GET, path, callback);
	
	public inline function post(?path: String, callback: Layer)
		return route(POST, path, callback);
		
	public inline function delete(?path: String, callback: Layer)
		return route(DELETE, path, callback);
		
	public inline function head(?path: String, callback: Layer)
		return route(HEAD, path, callback);
		
	public inline function options(?path: String, callback: Layer)
		return route(OPTIONS, path, callback);
		
	public inline function patch(?path: String, callback: Layer)
		return route(PATCH, path, callback);
		
	public inline function put(?path: String, callback: Layer)
		return route(PUT, path, callback);
	
	public function route(?method: Method, ?path: String, callback: Layer, end = true)
		return add(function(req: Request, res: Response, next: Void -> Void) {
			return 
				if (path != null) {
					var matcher = Path2EReg.toEReg(path, {end: end});
					if (!matcher.ereg.match(req.path)) {
						next();
					} else {
						var params: DynamicAccess<String> = {};
						for (i in 0 ... matcher.keys.length)
							params.set(matcher.keys[i].name, matcher.ereg.matched(i+1));
						req.params = cast params;
						req.path = end ? req.path : matcher.ereg.matchedRight();
						callback(req, res, next);
					}
				} else {
					req.params = null;
					req.path = req.path == null ? req.url.path : req.path;
					callback(req, res, next);
				}
		});
	
	public inline function use(?path: String, callback: Layer)
		return route(path, callback, false);
		
	public function serve(req: IncomingRequest) {
		return 
			try toHandler().process(req)
			catch (e: Dynamic) {
				var res = new Response();
				res.error('Unexpected exception: $e');
				res.future;
			}
	}
	
	public function layer(req, res, last) {
		var iter = this.iterator();
		function next()
			if (iter.hasNext())
				iter.next()(req, res, next)
			else
				last();
		next();
	}
	
	@:to
	public inline function toLayer(): Layer
		return layer;
		
	@:to
	public inline function toHandler(): Handler
		return toLayer();
	
	inline function container(port)
		return (
			#if embed
				new TcpContainer(port)
			#elseif php
				PhpContainer.inst
			#elseif neko
				ModnekoContainer.inst
			#elseif nodejs
				new NodeContainer(port)
			#else
				#error
			#end
		);
		
	// Todo: add options (watch, notfound, etc)
	public inline function listen(port: Int = 80): Future<ContainerResult> {
		var container = container(port);
		
		#if (embed && haxe_ver < 3.300)
		
		// Work around for https://github.com/haxetink/tink_runloop/issues/4
		var trigger = Future.trigger();
		@:privateAccess tink.RunLoop.create(function()
			container.run(serve).handle(trigger.trigger)
		);
		return trigger.asFuture();
		
		#else
		
		return container.run(serve);
		
		#end
	}

}