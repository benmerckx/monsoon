package;
import monsoon.middleware.Body;

using Monsoon;

class Run {

	public static function main() {
		var app = new Monsoon();
		
		app.route('/', function(req: Request, res: Response) res.send('ok'));
		
		app.routes([
			'/arg/:arg' => testArgumentInt,
			'/arg/:arg' => testArgumentString,
			'/hello' => function(req, res) res.send('world'),
			Post('/post') => testMiddleware
		]);
		
		var port = #if (sys || nodejs) Sys.args().length > 0 ? Std.parseInt(Sys.args()[0]) : 80 #else 80 #end;
		app.listen(port);
		
		#if (embed || nodejs)
		Sys.print(target()+' listening on '+port);
		#end
	}
	
	static function testArgumentInt(req: Request<{arg: Int}>, res: Response)
		res.json({arg: req.params.arg});
	
	static function testArgumentString(req: Request<{arg: String}>, res: Response)
		res.json({arg: req.params.arg});
		
	static function testMiddleware(req: Request, res: Response, body: Body)
		res.json({body: Std.string(body)});
		
	static function target() 
		return
			#if cpp
			'cpp'
			#elseif neko
			'neko'
			#elseif nodejs
			'nodejs'
			#else
			''
			#end
		;
	
}