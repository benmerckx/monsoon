package monsoon;

import tink.io.Source;
import tink.http.KeyValue;

#if (embed || nodejs)
import tink.io.Sink;
import tink.RunLoop;
import tink.concurrent.Queue;
import haxe.io.BytesOutput;
#end

using tink.CoreApi;

private class Impl {
	var source: Source;
	var body: String = null;
	
	public function new(source: Source) {
		this.source = source;
	}
	
	public function toString(): String {
		if (body != null) 
			return body;
		#if (embed || nodejs)
		// This checks for LimitedSource vd StdSource, otherwise this fails if there's no post data - todo: find a proper way to check
		if (!Reflect.hasField(source, 'surplus')) 
			return body = '';
		var queue = new Queue<Outcome<String, Error>>();
		RunLoop.current.work(function () {
			var buf = new BytesOutput();
			source.pipeTo(Sink.ofOutput('HTTP request body buffer', buf)).handle(function (x) queue.add(switch x {
				case AllWritten: 
					Success(buf.getBytes().toString());
				case SourceFailed(e):
					Failure(e);
				default: 
					Failure(null);
			}));
		});
		body = queue.await().sure();
		return body;
		#end
		#if ((!embed && neko) || php)
		var buffer = #if neko neko #elseif php php #end.Web.getPostData();
		return body = buffer == null ? '' : buffer;
		#end
		return body = '';
	}
	
	public function parseQueryString(): Map<String, String> {
		if (body == null)
			body = toString();
		return [
			for (p in KeyValue.parse(body))
				StringTools.urlDecode(p.a) => (p.b == null ? null : StringTools.urlDecode(p.b))
		];
	}
}

abstract Body(Impl) {
	inline public function new(source: Source)
		this = new Impl(source);
	
	@:to
	public function toString(): String
		return this.toString();
	
	@:to 
	// todo: keyvalue is not ok for a post body with multiple keys
	public function parseQueryString(): Map<String, String>
		return this.parseQueryString();
}