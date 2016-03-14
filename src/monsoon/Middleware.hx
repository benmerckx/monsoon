package monsoon;

interface ConfigurableMiddleware {
	public function setRouter(router: Router): Void;
}

typedef Middleware = {
	public function new(router: Router): Void;
}