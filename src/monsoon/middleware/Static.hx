package monsoon.middleware;

import monsoon.Method;
import monsoon.Middleware.ConfigurableMiddleware;
import monsoon.Router;
import sys.FileSystem;
import haxe.io.Path;

using Monsoon;

typedef StaticOptions = {
	index: Array<String>
}

class Static implements ConfigurableMiddleware {
	
	var directory: String;
	var options = {
		index: ['index.html', 'index.htm']
	};
	
	private function new(directory: String, ?options: StaticOptions) {
		this.directory = directory;
		Monsoon.concatOptions(this.options, options);
	}
	
	public function setRouter(router: Router) {
		router.route('*path', process);
	}
	
	function process(request: Request<{path: String}>, response: Response) {
		var path = Path.join([directory, request.params.path]);
		if (request.method != Method.Get || !FileSystem.exists(path)) {
			request.next();
			return;
		}
		if (FileSystem.isDirectory(path)) {
			// check for index
			var found = false;
			for (file in options.index) {
				var location = Path.join([path, file]);
				if (FileSystem.exists(location)) {
					path = location;
					found = true;
					break;
				}
			}
			if (!found) {
				request.next();
				return;
			}
		}
		response.sendFile(path);
	}
	
	public static function serve(directory: String, ?options: StaticOptions) {
		return new Static(directory, options);
	}
	
}