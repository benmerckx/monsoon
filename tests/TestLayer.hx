package;

import buddy.*;
import haxe.Json;
import tink.http.Handler;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import tink.http.Request;
import tink.http.Response;
import monsoon.Request;
import monsoon.Response;
import monsoon.middleware.Static;

using buddy.Should;
using tink.CoreApi;

class TestLayer extends BuddySuite {

	public function new() {		
        var app = new Monsoon();
		
		app.use(Static.serve('.'));
		
		app.use('/:foo', function(req, res, next) {
			res.status(600);
			next();
		});
		app.route('/:a', function(req, res, next) {
			trace(res.header.statusCode);
			res.send('index');
		});
		
		
		
		app
		.toHandler()
		.process(new IncomingRequest('localhost', new IncomingRequestHeader(GET, '/haxelib.json', '1.1', []), IncomingRequestBody.Plain('')))
		.handle(function(res) {
			res.body.all().handle(function(b) {
				trace(b.toString());
			});
		});
	}
	
}