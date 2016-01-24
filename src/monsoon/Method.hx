package monsoon;

@:enum abstract Method(String) from String to String {
  var Delete = "delete";
  var Get = "get";
  var Head = "head";
  var Options = "options";
  var Patch = "patch";
  var Post = "post";
  var Put = "put";
}