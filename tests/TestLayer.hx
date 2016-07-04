package;

import buddy.*;
import haxe.Json;
import monsoon.Layer;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import tink.http.Response;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestLayer extends BuddySuite {

	public function new() {
        var app = new Monsoon();
		app.get('/', function(req) {
			return Future.sync(('abc': OutgoingResponse));
		});
		app.get('/', function(req) {
			return Future.sync(('index': OutgoingResponse));
		});
		app.listen();
	}
	
}