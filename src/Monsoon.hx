package;

typedef ContainerMode = monsoon.App.ContainerMode;
typedef Response = monsoon.Response;
typedef App = monsoon.App;
typedef Router<P> = monsoon.Router<P>;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}