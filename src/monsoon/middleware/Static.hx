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
	public function process(req: Request, res: Response, next: Void -> Void) {
		var path = FileSystem.absolutePath(directory+req.path);
		
		if (req.method != GET) {
			next(); return;
		}
			
		if (!@await FileSystem.exists(path)) {
			next(); return;
		}
					
		if (@await FileSystem.isDirectory(path)) {
			for (file in options.index) {
				var location = Path.join([path, file]);
				if (@await FileSystem.exists(location))
					return res.sendFile(location);
			}
			next(); return;
		}
			
		return res.sendFile(path);
	}
	
	public static function serve(directory: String, ?options: StaticOptions) {
		return new Static(directory, options);
	}
	
}