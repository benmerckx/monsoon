package monsoon;

import monsoon.Router;
using tink.CoreApi;

interface Matcher<P> {
	public function matchRoute(request: Request, path: P): Outcome<Dynamic, Noise>;
}