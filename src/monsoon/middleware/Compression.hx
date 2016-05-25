package monsoon.middleware;

import monsoon.Middleware.ConfigurableMiddleware;
import monsoon.Router;
import monsoon.Response.Output;
#if nodejs
import js.node.Buffer;
import js.node.Zlib;
#else
import haxe.io.BytesBuffer;
import haxe.crypto.Crc32;
#end

using Monsoon;

class Compression implements ConfigurableMiddleware {
	
	var level: Int = 9;
	
	public function new(?level: Int) {
		if (level != null)
			this.level = level;
	}
	
	public function setRouter(router: Router) {
		router.route(process);
	}
	
	function process(request: Request, response: Response) {
		var accept = request.get('accept-encoding');
		if (accept == null || accept.indexOf('gzip') == -1)
			return request.next();
			
		response.done.asFuture().handle(function(_) {
			var out = @:privateAccess response.output;
			var input = switch out {
				case String(s): haxe.io.Bytes.ofString(s);
				case Bytes(b): b;
			}		
			#if nodejs
			// todo: do this async someway
			var bytes = Zlib.gzipSync(Buffer.hxFromBytes(input), {level: level}).hxToBytes();
			#else
			var buffer = new BytesBuffer();
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
			#end
			
			response.set('content-encoding', 'gzip');
			response.set('content-length', Std.string(bytes.length));
			@:privateAccess response.output = Output.Bytes(bytes);
		});
		request.next();
	}
	
}