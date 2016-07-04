package monsoon;

import tink.http.Container;
import tink.http.containers.*;
import tink.http.Header.HeaderField;
import tink.http.Request;
import tink.http.Response;
import tink.core.Future;
import tink.http.Handler;

using Lambda;
using tink.CoreApi;

typedef Layer = IncomingRequest -> Handler -> Future<OutgoingResponse>;

@:forward
abstract Monsoon(Array<Layer>) from Array<Layer> {
	
	public inline function new()
		this = [];
			
	public inline function get(path: String, handler: Handler)
		return add(function (req, next)
			return
				if (req.header.uri == path)
					handler.process(req)
				else
					next.process(req)
		);
	
	inline function toHandler(notFound: Handler): Handler
		return this.fold(
			function(curr, prev): Handler
				return function (req)
					return curr(req, prev), 
			notFound
		);
		
	public inline function add(layer: Layer): Monsoon {
		this.unshift(layer);
		return this;
	}
	
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