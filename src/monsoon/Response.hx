package monsoon;

import haxe.io.Bytes;
import haxe.Json;
import tink.http.Response;
import tink.http.Header.HeaderField;
import tink.io.IdealSource;
import asys.io.File;
import mime.Mime;

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
	
	public var after(default, null): Array<Void -> Future<Noise>> = [];
	public var headers(default, null): Map<String, String>;
	var done = Future.trigger();
	var cookies: Array<Cookie>;
	var code: Int;
	var output: IdealSource;
	
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
		cookies.push({name: name, value: value, options: options});
		return this;
	}
	
	public function json(output: Dynamic, ?space) {
		headers.set('content-type', 'application/json');
		send(Json.stringify(output, null, space));
	}
		
	public function redirect(code = 302, url: String) {
		this.code = code;
		headers = ['location' => url];
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
		output = File.readStream(path).idealize(function(e)
			error('Could not read file: '+path)
		);
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
		} else {
			buffer += ";";
		}
		return new HeaderField('set-cookie', buffer);
	}
	
	#if (!embed && neko)
	function nekoCookie(cookie: Cookie) {
		// Neko does not set multiple headers of the same name, so we must use setCookie instead of pushing a header in the response
		var options: CookieOptions = {expires: null, domain: null, path: null, secure: null, httpOnly: null};
		if (cookie.options != null)
			for (option in Reflect.fields(cookie.options))
				Reflect.setField(options, option, Reflect.field(cookie.options, option));
		neko.Web.setCookie(cookie.name, cookie.value, options.expires, options.domain, options.path, options.secure, options.httpOnly);
	}
	#end
		
	function tinkHeaders() {
		var cookies = [];
		#if (!embed && neko)
		this.cookies.map(nekoCookie);
		#else
		cookies = this.cookies.map(encodeCookie);
		#end
		return [for (key in headers.keys())
			new HeaderField(key, headers.get(key))
		].concat(cookies);
	}
	
	@:allow(monsoon.Monsoon)
	function tinkResponse()
		return new OutgoingResponse(
			new ResponseHeader(code, code > 400 ? 'ERROR' : 'OK', tinkHeaders()),
			output
		);
		
}