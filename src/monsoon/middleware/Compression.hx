package monsoon.middleware;

import haxe.io.BytesOutput;
import haxe.io.Bytes;
import mime.Mime;
import tink.io.IdealSource;
import tink.io.Sink;
import tink.io.Worker;
#if nodejs
import js.node.Buffer;
import js.node.Zlib;
#else
import haxe.io.BytesBuffer;
import haxe.crypto.Crc32;
#end

using Monsoon;
using tink.CoreApi;

@:access(monsoon.Response)
class Compression {
	
	var level: Int = 9;
	
	public function new(?level: Int) {
		if (level != null)
			this.level = level;
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
		buffer.addByte(level == 9 ? 2 : 4);
		buffer.addByte(0x03);
	}
	#end
	
	function finalizeResponse(response: Response, bytes: Bytes) {
		response.set('content-encoding', 'gzip');
		response.set('content-length', Std.string(bytes.length));
		response.body = bytes;
	}
	
	public function process(request: Request, response: Response, next: Void -> Void) {
		var accept = request.get('accept-encoding');
		
		if (accept == null || accept.indexOf('gzip') == -1) {
			next(); return;
		}
			
		response.after(function(res) {
			// Only compress types for which it makes sense
			var type = res.get('content-type');
			if (type == null) 
				return Future.sync(res);
			var mime = Mime.db.get(type);
			if (mime == null) 
				return Future.sync(res);
			if (mime.compressible == null || !mime.compressible)
				return Future.sync(res);
			
			var trigger = Future.trigger();
			var out = response.body;
			var buffer = new BytesOutput();
			var input: Bytes;
			
			out.pipeTo(Sink.ofOutput('response output buffer', buffer, Worker.EAGER))
			.handle(function (x) switch x {
				case AllWritten:
					input = buffer.getBytes();	
					#if nodejs
						Zlib.gzip(Buffer.hxFromBytes(input), {level: level}, function(err, buffer) {
							if (err != null) {
								response.error(err.message);
								return;
							}
							finalizeResponse(response, buffer.hxToBytes());
							trigger.trigger(res);
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
						// Remove zlib header/checksum
						buffer.addBytes(compressed, 2, compressed.length-6);
						buffer.addInt32(Crc32.make(input));
						buffer.addInt32(input.length);
						var bytes = buffer.getBytes();
						finalizeResponse(response, bytes);
						trigger.trigger(res);
					#end
				default:
					trigger.trigger(res);
			});
			return trigger.asFuture();
		});
		
		next();
	}
	
}