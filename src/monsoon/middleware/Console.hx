package monsoon.middleware;

import haxe.Json;
import haxe.PosInfos;
import monsoon.Response;
using tink.CoreApi;
using Monsoon;

typedef Log = Pair<Dynamic, PosInfos>;

@:access(monsoon.Response)
class Console {
	
	var logs: Array<Log> = [];
	var defaultTrace: Dynamic -> PosInfos -> Void;

	public function new(router: Router) {
		defaultTrace = haxe.Log.trace;
		haxe.Log.trace = function(v: Dynamic, ?info: PosInfos) logs.push(new Log(v, info));
		router.route(function(request: Request, response: Response) {
			response.done.asFuture().handle(function(_) {
				// Only print logs if this an html response
				var type = response.get('content-type');
				if (type == null || type.indexOf('text/html') == -1) {
					logs.map(function(log) defaultTrace(log.a, log.b));
					return;
				}
				switch response.output {
					case Output.String(s):
						response.output = Output.String(s+'\n<script>'+logs.map(logLine).join('')+'</script>');
					default:
				}
			});
			request.next();
		});
	}
	
	function logLine(log: Log) {
		return 'console.log("%c '+log.b.fileName+':'+log.b.lineNumber+' ", "background: #222; color: white", '+Json.stringify(log.a)+');';
	}
	
}