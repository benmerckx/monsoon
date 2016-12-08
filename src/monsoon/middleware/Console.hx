package monsoon.middleware;

import haxe.Json;
import haxe.PosInfos;
import monsoon.Response;
using tink.CoreApi;
using Monsoon;

typedef Log = Pair<Dynamic, PosInfos>;

@:access(monsoon.Response)
class Console {
	
	static var logs: Array<Log> = [];
	
	public function new() {
		haxe.Log.trace = 
			function(v: Dynamic, ?info: PosInfos) 
				logs.push(new Log(v, info));
	}

	public function process(req: Request, res: Response, next) {
		res.after(function(res) {
			var type = req.get('content-type');
			if (type != null && type.indexOf('text/html') > -1)
				res.body.append('\n<script>'+logs.map(logLine).join('')+'</script>');
			return Future.sync(res);
		});
		next();
	}
	
	function logLine(log: Log) {
		return 'console.log("%c '+log.b.fileName+':'+log.b.lineNumber+' ", "background: #222; color: white", '+Json.stringify(log.a)+');';
	}
	
	public static function serve()
		return new Console().process;
	
}