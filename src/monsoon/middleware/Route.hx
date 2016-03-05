package monsoon.middleware;

import monsoon.Matcher.ParamType;
import monsoon.Router.MiddlewareItem;

@:allow(monsoon.Router)
class Route<P> {

	public function new(router: Router) {}
	
	public var path(default, null): P;
	public var types(default, null): Array<ParamType>;
	public var middleware(default, null): Array<MiddlewareItem>;
	public var matcher(default, null): Matcher<P>;
	public var order(default, null): Int;
	
}