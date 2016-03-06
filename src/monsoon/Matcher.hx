package monsoon;

import haxe.io.Path;
import monsoon.Router;
using tink.CoreApi;

typedef ParamType = {
	name: String,
	type: String
}

interface Matcher<P> {
	public function transformInput(input: P): P;
	public function match(
		prefixes: Array<Any>, 
		request: Request<Dynamic>, 
		route: Route<P>
	): Outcome<Dynamic, Noise>;
}