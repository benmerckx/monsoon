package;


typedef ContainerMode = monsoon.App.ContainerMode;
typedef Response = monsoon.Response;
//typedef Request<T> = monsoon.Request<T>;
typedef App = monsoon.App;
typedef Router<P> = monsoon.Router<P>;
typedef RouteHelper = monsoon.macro.RouteHelper;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}