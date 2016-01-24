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
		function addPair(buf:StringBuf, name, value) {
			if(value == null) return;
			buf.add("; ");
			buf.add(name);
			buf.add(value);
		}
		var buf = new StringBuf();
		buf.add(name+'='+StringTools.urlEncode(value));
		if (options != null) {
			if (options.expires != null) 
				addPair(buf, "expires=", DateTools.format(options.expires, "%a, %d-%b-%Y %H:%M:%S GMT"));
			addPair(buf, "domain=", options.domain);
			addPair(buf, "path=", options.path);
			if (options.secure) addPair(buf, "secure", "");
			if (options.httpOnly) addPair(buf, "HttpOnly", "");
		}
		headers.set('Set-Cookie', buf.toString());
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