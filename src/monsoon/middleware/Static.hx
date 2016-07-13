package monsoon.middleware;

import asys.FileSystem;
import haxe.io.Path;
import monsoon.Request;
import tink.http.Handler;
import tink.http.Method;
import tink.http.Response.OutgoingResponse;

using tink.CoreApi;

typedef StaticOptions = {
	index: Array<String>
}

@await
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
	
	@await
	public function process(handler: Handler): Handler {
		return @await function(req: Request) {
			return Future.async(@await function (done: OutgoingResponse -> Void) {
				function next()
					handler.process(req).handle(done);
					
				var path = FileSystem.absolutePath(directory+req.path);
				
				if (req.method != GET || !@await FileSystem.exists(path))
					return next();
					
				if (@await FileSystem.isDirectory(path)) {
					for (file in options.index) {
						var location = Path.join([path, file]);
						if (@await FileSystem.exists(location))
							return done('index file');
					}
					return next();
				}
					
				return done(path);
			});
		}
	}
	
	public static function serve(directory: String, ?options: StaticOptions) {
		return new Static(directory, options).process;
	}
	
}