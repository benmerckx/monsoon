package;

typedef Monsoon = monsoon.Monsoon;

@:genericBuild(monsoon.macro.RequestBuilder.buildGeneric())
class Request<Rest> {}