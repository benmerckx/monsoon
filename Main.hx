import monsoon.PathMatcher;
using Monsoon;

class Main {
	public static function main() {		
		var router = new Router<Path>(new PathMatcher());
		router.route('/', function(request, response) {
			response.end('index');
		});
		router.route('/test', function(request, response) {
			response.end("test");
		});
		router.route('/app.n', function(request, response) {
			response.end("cgi test");
		});
		router.route('/test/:extra', function(request: Request<{extra: String}>, response) {
			response.end(request.params.extra);
		});
		
		var app = new App({mode: ContainerMode.Tcp, watch: true});
		app.use(router);
		app.listen();
	}
}