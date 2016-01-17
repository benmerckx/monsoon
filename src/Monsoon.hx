package;

typedef ContainerMode = monsoon.App.ContainerMode;
typedef Response = monsoon.Response;
typedef App = monsoon.App;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}