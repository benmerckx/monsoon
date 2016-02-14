package monsoon;

import tink.io.Source;
import tink.http.KeyValue;
#if embed
import tink.io.Sink;
import tink.RunLoop;
import tink.concurrent.Queue;
import haxe.io.BytesOutput;
#end
using tink.CoreApi;

abstract Body(Source) {

	inline public function new(source: Source) {
		this = source;
	}
	
	@:to
	public function toString(): String {
		#if embed
		// This checks for LimitedSource vd StdSource, otherwise this fails if there's no post data - todo: find a proper way to check
		if (!Reflect.hasField(this, 'surplus')) 
			return '';
		var queue = new Queue<Outcome<String, Error>>();
		RunLoop.current.work(function () {
			var buf = new BytesOutput();
			this.pipeTo(Sink.ofOutput('HTTP request body buffer', buf)).handle(function (x) queue.add(switch x {
				case AllWritten: 
					Success(buf.getBytes().toString());
				case SourceFailed(e):
					Failure(e);
				default: 
					Failure(null);
			}));
		});
		return switch queue.await() {
			case Success(s): s;
			default: '';
		}
		#end
		// todo: implement for other targets
		return '';
	}
	
	@:to 
	// todo: keyvalue is not ok for a post with multiple keys
	public function parseQueryString(): Map<String, String> {
		var body = toString();
		return [
			for (p in KeyValue.parse(body))
				p.a => (p.b == null ? null : StringTools.urlDecode(p.b))
		];
	}
	
}