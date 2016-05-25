package monsoon.middleware;

import monsoon.Method;
import monsoon.Router;
import asys.FileSystem;
import haxe.io.Path;

using Monsoon;

typedef StaticOptions = {
	index: Array<String>
}

class Static {
	
	var directory: String;
	var options = {
		index: ['index.html', 'index.htm']
	};
	
	private function new(directory: String, ?options: StaticOptions) {
		this.directory = directory;
		Monsoon.concatOptions(this.options, options);
	}
	
	public function process(request: Request, response: Response) {
		var path = Path.join([directory, request.path]);
		if (request.method != Method.Get) {
			request.next();
			return;
		}
		FileSystem.exists(path).handle(function(exists) {
			if (!exists) {
				request.next();
			} else {
				FileSystem.isDirectory(path).handle(function(isDir) {
					if (isDir) {
						var index = options.index;
						function tryNext() {
							if (index.length == 0) {
								request.next();
								return;
							}
							var file = index.shift();
							var location = Path.join([path, file]);
							FileSystem.exists(location).handle(function(exists) {
								if (exists) {
									response.sendFile(location);
								} else {
									tryNext();
								}
							});
						}
						tryNext();
					} else {
						response.sendFile(path);
					}
				});
			}
		});
	}
	
	public static function serve(directory: String, ?options: StaticOptions) {
		return new Static(directory, options);
	}
	
}