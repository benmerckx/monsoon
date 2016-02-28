package monsoon.middleware;
import monsoon.Response;

import monsoon.Middleware;
import monsoon.Request;
import tink.io.Source;
import tink.http.KeyValue;

#if (embed || nodejs)
import tink.io.Sink;
import tink.RunLoop;
import tink.concurrent.Queue;
import haxe.io.BytesOutput;
import tink.io.Worker;
import tink.io.Pipe.PipeResult;
#end

using tink.CoreApi;

class Body extends Middleware {
	var source: Source;
	var body: String = '';
	
	@:access(monsoon.RequestAbstr)
	override public function process(request:Request, response:Response) {
		source = request.request.body;
		
		#if embed
		// This checks for LimitedSource vd StdSource, otherwise this fails if there's no post data - todo: find a proper way to check
		if (!Reflect.hasField(source, 'surplus')) {
			done.trigger(true);
			return;
		}
		
		RunLoop.current.work(function () {
			var buf = new BytesOutput();
			source.pipeTo(Sink.ofOutput('HTTP request body buffer', buf)).handle(function (x) switch x {
				case AllWritten:
					body = buf.getBytes().toString();
					done.trigger(true);
				default: done.trigger(true);
			});
		});	
		return;
		#end
		
		#if nodejs
		var out = new BytesOutput();
		source
		.pipeTo(Sink.ofOutput('HTTP request body buffer', out, Worker.EAGER))
		.handle(function(x) {
			switch x {
				case AllWritten: body = out.getBytes().toString();
				default:
			}
			done.trigger(true);
		});
		return;
		#end
		
		#if (neko || php)
		var buffer = #if neko neko #elseif php php #end.Web.getPostData();
		body = buffer == null ? '' : buffer;
		done.trigger(true);
		#end
	}
	
	public function toMap(): Map<String, String>
		return [
			for (p in KeyValue.parse(body))
				StringTools.urlDecode(p.a) => (p.b == null ? null : StringTools.urlDecode(p.b))
		];
	
	public function toString() 
		return body;
}