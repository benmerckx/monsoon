package monsoon;

import tink.core.Future;

class Middleware {
	
	@:allow(monsoon.Monsoon)
	var done(default, null): FutureTrigger<Bool> = Future.trigger();
	
	public function new() {}
	
	public function process(request: Request, response: Response) {
		done.trigger(true);
	}
}