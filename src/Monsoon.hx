package;

typedef Monsoon = monsoon.Monsoon;
typedef Response = monsoon.Response;
typedef Layer = monsoon.Layer;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}