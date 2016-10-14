package;

import buddy.*;

@colors
class RunTests implements Buddy<[
	TestRequest,
	TestResponse,
	TestRouter,
	TestMiddleware,
	TestRouteController,
	TestStatic,
	TestByteRange,
	TestCompression
]> {
	#if php
	static function __init__()
		untyped __call__('ini_set', 'xdebug.max_nesting_level', 100000);
	#end
}