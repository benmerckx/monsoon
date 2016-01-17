package monsoon;

import tink.core.Future;
import tink.http.Response.OutgoingResponse;

typedef Response = MonsoonResponse;
class MonsoonResponse {
	public var done(default, never) = Future.trigger();
	
	public function new () {
	}
	
	public function end(str: String) {
		done.trigger((str: OutgoingResponse));
	}
}