package monsoon.middleware;

import monsoon.Response;
import monsoon.Middleware;
import monsoon.Request;
import tink.io.Source;
import tink.http.KeyValue;
import tink.io.Sink;
import haxe.io.BytesOutput;
import tink.io.Worker;

#if embed
import tink.RunLoop;
#end

using tink.CoreApi;

class Body extends Middleware {
	var source: Source;
	var body: String = '';
	
	@:access(monsoon.RequestAbstr)
	override public function process(request: Request, response: Response) {
		source = request.request.body;
		
		#if (embed && neko)
		// This checks for LimitedSource vd StdSource, otherwise this fails if there's no post data - todo: find a proper way to check
		if (!Reflect.hasField(source, 'surplus')) {
			done.trigger(true);
			return;
		}
		#end
		
		/*#if ((!embed && neko) || php)
		body = #if neko neko #elseif php php #end.Web.getPostData();
		if (body == null) body = '';
		done.trigger(true);
		return;
		#end*/
		
		#if embed RunLoop.current.work(function () { #end
			var buf = new BytesOutput();
			source
			.pipeTo(Sink.ofOutput('HTTP request body buffer', buf, Worker.EAGER))
			.handle(function (x) switch x {
				case AllWritten:
					body = buf.getBytes().toString();
					done.trigger(true);
				default: done.trigger(true);
			});
		#if embed }); #end
	}
	
	public function toMap(): Map<String, String>
		return [
			for (p in KeyValue.parse(body))
				StringTools.urlDecode(p.a) => (p.b == null ? null : StringTools.urlDecode(p.b))
		];
	
	public function toString() 
		return body;
}