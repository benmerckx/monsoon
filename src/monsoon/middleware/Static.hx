package monsoon.middleware;

import asys.FileSystem;
import haxe.io.Path;
import monsoon.Request;
import monsoon.Response;
import tink.http.Handler;
import tink.http.Method;
import tink.http.Request.IncomingRequest;
import tink.http.Response.OutgoingResponse;

using tink.CoreApi;

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
		if (options != null) 
			this.options = options;
	}
	
	public function process(req: Request, res: Response, next: Void -> Void) {
		var path = FileSystem.absolutePath(directory+req.path);

		if (req.method != GET) {
			next(); return;
		}
			
		FileSystem.exists(path).handle(function(exists) {
			if (!exists) {
				next(); return;
			}
			FileSystem.isDirectory(path).handle(function(isDir) {
				if (!isDir) {
					res.sendFile(path);
					return;
				}
				var iter = options.index.iterator();
				function tryNext() {
					if (!iter.hasNext()) {
						next();
						return;
					}
					var location = Path.join([path, iter.next()]);
					FileSystem.exists(location).handle(function(isFile) {
						if (!isFile) {
							tryNext();
							return;
						}
						res.sendFile(location);
					});
				}
				tryNext();
			});
		});
	}
	
	public static function serve(directory: String, ?options: StaticOptions) {
		return new Static(directory, options);
	}
	
}