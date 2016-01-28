
typedef Response = monsoon.Response;
typedef Monsoon = monsoon.Monsoon;
typedef Router<P> = monsoon.Router<P>;
typedef RouteHelper = monsoon.macro.RouteHelper;
typedef AppHelper = monsoon.macro.RouteHelper.AppHelper;
typedef Method = monsoon.PathMatcher.MethodPath;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}