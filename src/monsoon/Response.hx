package monsoon;

import haxe.Json;
import tink.http.Response;
import tink.http.Header.HeaderField;
import tink.io.IdealSource;
import sys.io.File;

using tink.CoreApi;

typedef Cookie = {
	name: String,
	value: String,
	options: Null<CookieOptions>
}

typedef CookieOptions = {
	?domain: String,
	?expires: Date,
	?httpOnly: Bool,
	?path: String,
	?secure: Bool,
}

@:keep
class Response {
	
	public var done(default, null) = Future.trigger();
	public var headers(default, null): Map<String, String>;
	var cookies: Array<Cookie>;
	var code: Int;
	var output: String = '';
	
	public function new () clear();
	
	public function status(code: Int) {
		this.code = code;
		return this;
	}
	
	public function clear() {
		headers = new Map();
		cookies = [];
		code = 200;
		return this;
	}
	
	public function cookie(name: String, value: String, ?options: CookieOptions) {
		#if (!embed && neko)
		// Neko does not set multiple headers of the same name, so we must use setCookie instead of pushing a header in the response
		neko.Web.setCookie(name, value, options.expires, options.domain, options.path, options.secure, options.httpOnly);
		#else
		cookies.push({name: name, value: value, options: options});
		#end
		return this;
	}
	
	public function json(output: Dynamic, ?space) {
		headers.set('content-type', 'application/json');
		send(Json.stringify(output, null, space));
	}
		
	public function redirect(code = 302, url: String) {
		this.code = code;
		headers = ['Location' => url];
		end();
	}
	
	public function error(code = 500, message: String) {
		clear()
		.set('content-type', 'text/plain; charset=utf-8')
		.status(code)
		.send(message);
	}
	
	public function set(key: String, value: String) {
		headers.set(key.toLowerCase(), value);
		return this;
	}
	
	public function get(key: String) {
		return headers.get(key);
	}
	
	public function end()
		send(null);
		
	public function send(output: String) {
		this.output = output;
		done.trigger(Noise);
	}
		
	function encodeCookie(cookie: Cookie) {
		var buffer = StringTools.urlEncode(cookie.name)+'='+StringTools.urlEncode(cookie.value);
		if (cookie.options != null) {
			if (cookie.options.expires != null) 
				buffer += "; expires="+DateTools.format(cookie.options.expires, "%a, %d-%b-%Y %H:%M:%S GMT");
			if (cookie.options.domain != null) 
				buffer += "; domain="+cookie.options.domain;
			if (cookie.options.path != null) 
				buffer += "; path="+cookie.options.path;
			if (cookie.options.secure != null && cookie.options.secure) 
				buffer += "; secure";
			if (cookie.options.httpOnly != null && cookie.options.httpOnly)
				buffer += "; HttpOnly";
		}
		return new HeaderField('Set-Cookie', buffer);
	}
		
	function tinkHeaders()
		return [for (key in headers.keys())
			new HeaderField(key, headers.get(key))
		].concat(cookies.map(encodeCookie));
	
	@:allow(monsoon.Monsoon)
	function tinkResponse() 
		return new OutgoingResponse(
			new ResponseHeader(code, code > 400 ? 'OK' : 'ERROR', tinkHeaders()),
			output
		);
}