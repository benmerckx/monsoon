package monsoon.middleware;

import monsoon.Method;
import monsoon.Router;
import sys.FileSystem;
import haxe.io.Path;

using Monsoon;

typedef StaticOptions = {
	index: Array<String>
}

class Static {
	
	public static function serve(directory: String, ?options: StaticOptions) {
		options = Monsoon.concatOptions({
			index: ['index.html']
		}, options);
		return function(request: Request, response: Response) {
			var path = Path.join([directory, request.path]);
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
	}
	
}