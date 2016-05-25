package monsoon;

typedef RouteController = {
	function createRoutes(router : Router) : Void;
}

typedef Middleware = {
	function process(request: Request, response: Response): Void;
}