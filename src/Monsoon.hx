package;

typedef Response = monsoon.Response;
typedef Monsoon = monsoon.Monsoon;
typedef Router = monsoon.Router;
typedef RouteHelper = monsoon.macro.RouteHelper;
typedef AppHelper = monsoon.macro.RouteHelper.AppHelper;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}