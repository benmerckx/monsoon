package monsoon.middleware;

import monsoon.Response;
import tink.http.Request.IncomingRequest;
import tink.http.Response.OutgoingResponse;

using tink.CoreApi;

class ThreadServer {

	public static function serve(threads: Int): Layer {
		var queue = new tink.concurrent.Queue<Void -> Void>();
		
		for (i in 0 ... threads) {
			new tink.concurrent.Thread(function () 
				while (true) {
					var next = queue.await();
					next();
				}
			);
		}
		
		return function (request: Request, response: Response, next: Void -> Void) { 
			queue.push(next);
		}
	}
	
}