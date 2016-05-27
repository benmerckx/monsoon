package;

import haxe.Json;
import tink.http.Header.HeaderField;
import tink.http.Method;
import tink.http.Request.IncomingRequest;
import tink.http.Request.IncomingRequestHeader;
import tink.http.Response.OutgoingResponse;
import tink.io.Buffer;

class TestTools {

	public static function request(?method: Method, path: String, ?fields: TinkHeaderFields, body = '')
		return new IncomingRequest('127.0.0.1', new IncomingRequestHeader(method == null ? GET : method, path, '1.1', fields == null ? [] : fields), body);
	
}

@:forward
abstract TinkResponse(OutgoingResponse) from OutgoingResponse {
	public var status(get, never): Int;
	function get_status() return this.header.statusCode;
	
	public var body(get, never): String;
	function get_body() {
		var buffer = Buffer.alloc();
		this.body.read(buffer);
		return buffer.content().toString();
	}
	
	public var bodyJson(get, never): Dynamic;
	function get_bodyJson()
		return Json.parse((this: TinkResponse).body);
}

abstract TinkHeaderFields(Array<HeaderField>) from Array<HeaderField> to Array<HeaderField> {
	@:from public static function fromMap(map: Map<String, String>)
		return ([for (key in map.keys()) new HeaderField(key, map.get(key))]: TinkHeaderFields);
}