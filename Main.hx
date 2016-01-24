import monsoon.PathMatcher;

using Monsoon;

class Main {
	public static function main() {		
		var router = new Router<Path>(new PathMatcher());
		router.route('/', index);
		router.route('/test', function(request: Request, response) {
			response.end("test");
		});
		router.route('/app.n', function(request: Request, response) {
			response.end("cgi test");
		});
		router.route('/test/:extra', function(request: Request<{extra: Int}>, response) {
			response.end('Nr: '+request.params.extra);
		});
		
		var app = new App({mode: ContainerMode.Tcp, watch: true});
		app.use(router);
		app.listen();
	}
	
	static function index(request: Request<{test: String}>, response) {
		response.end("index");
	}
}