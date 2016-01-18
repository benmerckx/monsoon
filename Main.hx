using Monsoon;

class Main {
	public static function main() {		
		var app = new App({mode: ContainerMode.Tcp, watch: true});
		app.route('/', function(request, response) {
			response.end("index");
		});
		app.route('/test', function(request, response) {
			response.end("test");
		});
		app.route('/app.n', function(request, response) {
			response.end("cgi test");
		});
		app.route('/test/:extra', function(request: Request<{extra: String}>, response) {
			response.end(request.params.extra);
		});
		app.listen();
	}
}