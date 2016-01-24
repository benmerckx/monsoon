package monsoon;

import monsoon.Router;
using tink.CoreApi;

interface Matcher<P> {
	public function match(request: Request<Dynamic>, path: P, types: Array<ParamType>): Outcome<Dynamic, Noise>;
}