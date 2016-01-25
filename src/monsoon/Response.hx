package monsoon;

import haxe.Json;
import tink.core.Future;
import tink.http.Response;
import tink.http.Header.HeaderField;
import tink.io.IdealSource;

typedef CookieOptions = {
	?domain: String,
	//?encode: T -> String,
	?expires: Date,
	?httpOnly: Bool,
	?path: String,
	?secure: Bool,
	//?signed: Bool
}

class Response {
	
	public var done(default, never) = Future.trigger();
	public var headers(default, null): Map<String, String> = new Map();
	var code = 200;
	
	public function new () {
		
	}
	
	public function status(code: Int) {
		this.code = code;
		return this;
	}
	
	public function cookie(name: String, value: String, ?options: CookieOptions) {
		var buffer = StringTools.urlEncode(name)+'='+StringTools.urlEncode(value);
		if (options != null) {
			if (options.expires != null) 
				buffer += "; expires="+DateTools.format(options.expires, "%a, %d-%b-%Y %H:%M:%S GMT");
			if (options.domain != null) 
				buffer += "; domain="+options.domain;
			if (options.path != null) 
				buffer += "; path="+options.path;
			if (options.secure != null && options.secure) 
				buffer += "; secure";
			if (options.httpOnly != null && options.httpOnly)
				buffer += "; HttpOnly";
		}
		headers.set('Set-Cookie', buffer);
	}
		
	public function send(output: IdealSource) 
		done.trigger(new OutgoingResponse(
			new ResponseHeader(code, code > 400 ? 'OK' : 'ERROR', tinkHeaders()),
			output
		));
	
	public function json(output: Dynamic, ?space) {
		headers.set('Content-Type', 'application/json');
		send(Json.stringify(output, null, space));
	}
		
	public function redirect(code: Int = 302, url: String) {
		this.code = code;
		headers = ['Location' => url];
		end();
	}
	
	public function end()
		send(null);
		
	function tinkHeaders()
		return [for (key in headers.keys())
			new HeaderField(key, headers.get(key))
		];
	
}