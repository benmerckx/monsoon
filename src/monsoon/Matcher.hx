package monsoon;

import haxe.io.Path;
import monsoon.Router;
using tink.CoreApi;

interface Matcher<P> {
	public function transformInput(input: P): P;
	public function match(request: Request<Dynamic>, path: P, types: Array<ParamType>): Outcome<Dynamic, Noise>;
}