package;

import monsoon.middleware.Body;
import monsoon.middleware.Static;

using Monsoon;

class Controller {
	public function new(router: Router) {
		router.get('/', function(req: Request, res: Response) res.json({route: 'controller_index'}));
		router.get('/path', function(req: Request, res: Response) res.json({route: 'controller_path'}));
	}
}

class Run {

	inline static var target = #if cpp 'cpp' #elseif neko 'neko' #elseif nodejs 'nodejs' #elseif java 'java' #else '' #end;

	public static function main() {
		var app = new Monsoon();

		app.route('/public', Static.serve('public'));

		app.route('/', function(req: Request, res: Response) res.send('ok'));

		app.get([
			'/controller' => Controller,
			'/arg/:arg' => testArgumentInt,
			'/arg/:arg' => testArgumentString,
			'/cookie' => function(req: Request, res: Response) res.cookie('name', 'value').send('ok'),
			'/header' => function(req: Request, res: Response) res.set('test', req.get('test')).send('ok')
		]);

		app.post([
			'/post' => testMiddleware
		]);

		var port = #if (sys || nodejs) Sys.args().length > 0 ? Std.parseInt(Sys.args()[0]) : 80 #else 80 #end;
		app.listen(port);

		#if (embed || nodejs)
		Sys.print(target+' listening on '+port);
		#end
	}

	static function testArgumentInt(req: Request<{arg: Int}>, res: Response)
		res.json({arg: req.params.arg});

	static function testArgumentString(req: Request<{arg: String}>, res: Response)
		res.json({arg: req.params.arg});

	static function testMiddleware(req: Request, res: Response, body: Body)
		res.json({body: Std.string(body)});
}
