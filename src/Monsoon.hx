package;

typedef Monsoon = monsoon.Monsoon;
typedef Response = monsoon.Response;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}