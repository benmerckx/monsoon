package monsoon.middleware;

import monsoon.Middleware.ConfigurableMiddleware;
import monsoon.Router;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import tink.io.IdealSource;
import tink.io.Sink;
#if nodejs
import js.node.Buffer;
import js.node.Zlib;
#else
import haxe.io.BytesBuffer;
import haxe.crypto.Crc32;
#end

using Monsoon;
using tink.CoreApi;

class Compression implements ConfigurableMiddleware {
	
	var level: Int = 9;
	
	public function new(?level: Int) {
		if (level != null)
			this.level = level;
	}
	
	public function setRouter(router: Router) {
		router.route(process);
	}
	
	#if !nodejs
	function writeGzipHeader(buffer: BytesBuffer) {
		buffer.addByte(0x1f);
		buffer.addByte(0x8b);
		buffer.addByte(8);
		buffer.addByte(0);
		buffer.addByte(0);
		buffer.addByte(0);
		buffer.addByte(0);
		buffer.addByte(0);
		// todo: fill this out proper
		buffer.addByte(level == 9 ? 2 : 4);
		buffer.addByte(0x03);
	}
	#end
	
	function finalizeResponse(response: Response, bytes: Bytes) {
		response.set('content-encoding', 'gzip');
		response.set('content-length', Std.string(bytes.length));
		@:privateAccess response.output = bytes;
	}
	
	function process(request: Request, response: Response) {
		var accept = request.get('accept-encoding');
		if (accept == null || accept.indexOf('gzip') == -1)
			return request.next();
			
		response.after.push(function() {
			var trigger = Future.trigger();
			var out = @:privateAccess response.output;
			var buffer = new BytesOutput();
			var input: Bytes;
			out.pipeTo(Sink.ofOutput('response output buffer', buffer))
			.handle(function (x) switch x {
				case AllWritten:
					input = buffer.getBytes();					
					#if nodejs
						Zlib.gzip(Buffer.hxFromBytes(input), {level: level}, function(err, buffer) {
							if (err != null) {
								response.error(500, err.message);
								return;
							}
							finalizeResponse(response, buffer.hxToBytes());
							trigger.trigger(Noise);
						});
					#else
						var buffer = new BytesBuffer();
						writeGzipHeader(buffer);
						var compressed;
						#if !php
						compressed = haxe.zip.Compress.run(input, level);
						#else
						var c = untyped __call__("gzcompress", input.toString(), level);
						compressed = haxe.io.Bytes.ofString(c);
						#end
						// Remove zlib header
						buffer.addBytes(compressed, 2, compressed.length-2);
						buffer.addInt32(Crc32.make(input));
						buffer.addInt32(input.length);
						var bytes = buffer.getBytes();
						finalizeResponse(response, bytes);
						trigger.trigger(Noise);
					#end
				default:
			});
			return trigger.asFuture();
		});
		request.next();
	}
	
}