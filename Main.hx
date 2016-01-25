import monsoon.PathMatcher;

using Monsoon;

class Main {
	public static function main() {		
		var app = new App({watch: true});
		
		app.route('/', index);
		app.route(Post('/post'), function(request: Request, response: Response) {
			response.send("post");
		});
		app.route('/app.n', function(request: Request, response: Response) {
			response.send("cgi test");
		});
		app.route('/test/:extra', function(request: Request<{extra: Float}>, response: Response) {
			response.cookie('test', 'hello', {path: '/test'});
			response.json(request.params);
		});
		app.route('/test/:extra', function(request: Request<{extra: String}>, response: Response) {
			response.send('String: '+request.params.extra);
		});
		
		app.listen();
	}
	
	static function index(request: Request, response: Response) {
		response.send(request.method);
	}
}