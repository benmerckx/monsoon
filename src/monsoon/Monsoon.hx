package monsoon;

import haxe.DynamicAccess;
import tink.http.Container;
import tink.http.containers.*;
import tink.http.Request;
import tink.http.Response;
import tink.core.Future;
import tink.http.Handler;
import tink.http.Method;
import monsoon.Request;
import monsoon.Response;
import monsoon.Layer;
import path2ereg.Path2EReg;
import haxe.Constraints;

using Lambda;
using tink.CoreApi;

@:callable
abstract RouteCallback(Function) {
	
	inline function new(func) 
		this = func;
	
	@:from
	public inline static function fromMiddleware(middleware: Handler -> Handler)
		return new RouteCallback((middleware: Layer));
		
	@:from
	public inline static function fromAnyShort<Req>(func: Req -> Future<OutgoingResponse>)
		return new RouteCallback(function(req, next) return func(req));
		
	@:from
	public inline static function fromAny<Req>(func: Req -> HandlerFunction -> Future<OutgoingResponse>)
		return new RouteCallback(func);
	
}

@:forward
abstract Monsoon(List<Layer>) from List<Layer> {
	
	public inline function new()
		this = new List();
		
	inline function add(layer: Layer): Monsoon {
		this.push(layer);
		return this;
	}
		
	public inline function get<T: Function>(path: String, callback: RouteCallback)
		return route(GET, path, callback);
	
	public inline function post<T: Function>(path: String, callback: RouteCallback)
		return route(POST, path, callback);
	
	public function route(?method: Method, ?path: String, callback: RouteCallback, end = true)
		return add(function(req, next) {
			return 
				if (path != null) {
					var matcher = Path2EReg.toEReg(path, {end: end});
					if (!matcher.ereg.match(req.header.uri.path)) {
						next(req);
					} else {
						var params: DynamicAccess<String> = {};
						for (i in 0 ... matcher.keys.length)
							params.set(matcher.keys[i].name, matcher.ereg.matched(i+1));
						var request = new MatchedRequest(req, params, end ? req.header.uri.path : matcher.ereg.matchedRight());
						callback(request, next);
					}
				} else {
					callback(req, next);
				}
		});
	
	public inline function use(?path: String, callback: RouteCallback)
		return route(path, callback, false);
	
	public inline function toHandler(last: Handler): Handler
		return this.fold(
			function(curr, prev): Handler
				return function (req)
					return curr(req, prev), 
			last
		);
	
	// todo: add options (watch, notfound, etc)
	public inline function listen(port: Int = 80): Future<ContainerResult>
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
		).run(toHandler(
			function (req)
				return Future.sync(('404 not found': OutgoingResponse))
		));

}