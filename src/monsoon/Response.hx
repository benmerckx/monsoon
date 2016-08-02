package monsoon;

import haxe.io.Bytes;
import haxe.Json;
import tink.core.Future.FutureTrigger;
import tink.http.Header.HeaderName;
import tink.http.Response;
import tink.http.Header.HeaderField;
import tink.io.IdealSource;
import asys.io.File;
import mime.Mime;

using tink.CoreApi;

typedef CookieOptions = {
	?expires: Date,
	?domain: String,
	?path: String,
	?secure: Bool,
	?scriptable: Bool
}

class Response {
	
	public var future(default, null): Future<OutgoingResponse>;
	public var header(default, null): ResponseHeader;
	public var body(default, null): IdealSource;
	var done: FutureTrigger<OutgoingResponse>;
	var transform: Response -> Future<Response>;
	
	public function new() 
		clear();
	
	public function status(code: Int) {
		@:privateAccess
		header.statusCode = code;
		return this;
	}
	
	public function clear() {
		header = new ResponseHeader(200, 'OK', []);
		body = '';
		done = Future.trigger();
		future = done.asFuture();
		transform = function (res) return Future.sync(this);
		return this;
	}
	
	public function cookie(name: String, value: String, ?options: CookieOptions) {
		header.fields.push(HeaderField.setCookie(name, value, options));
		return this;
	}
	
	public function json(output: Dynamic, ?space) {
		set('content-type', 'application/json');
		send(Json.stringify(output, null, space));
	}
		
	public function redirect(code = 302, url: String) {
		clear()
		.status(302)
		.set('location', url)
		.end();
	}
	
	public function error(code = 500, message: String) {
		clear()
		.set('content-type', 'text/plain; charset=utf-8')
		.status(code)
		.send(message);
	}
	
	public function set(key: String, value: String) {
		var name: HeaderName = key;
		switch header.byName(name) {
			case Success(line): 
				for (field in header.fields)
					if (field.name == name)
						@:privateAccess field.value = value;
			default:
				header.fields.push(new HeaderField(name, value));
		}
		return this;
	}
	
	public function get(key: String): Null<String>
		return switch header.byName(key) {
			case Success(v): v;
			default: null;
		}
	
	public function end()
		send(null);
		
	public function send(output: String) {
		body = output;
		finalize();
	}
	
	function finalize() {
		transform(this).handle(function(res) {
			done.trigger(res.toOutgoingResponse());
		});
	}
	
	public function sendFile(path: String, ?contentType: String) {
		if (contentType == null) {
			var type = Mime.lookup(path);
			if (type == null) 
				type = 'application/octet-stream';
			var info = Mime.db.get(type);
			contentType = type;
			if (info.charset != null)
				contentType += '; charset='+info.charset.toLowerCase();
		}
		set('content-type', contentType);
		body = File.readStream(path).idealize(function(e)
			error('Could not read file: '+path)
		);
		finalize();
	}
	
	public static function fromOutgoingResponse(res: OutgoingResponse) {
		var result = new Response();
		result.header = res.header;
		result.body = res.body;
		return result;
	}
	
	public function after(cb: Response -> Future<Response>) {
		var old = transform;
		transform = function(res) {
			return old(res).flatMap(function(res) {
				return cb(res);
			});
		}
	}
	
	function toOutgoingResponse()
		return new OutgoingResponse(header, body);
	
}