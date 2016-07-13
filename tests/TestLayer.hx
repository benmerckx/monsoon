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
		
		/*var mw = function(handler: Handler) {
			return function (req) {
				trace('mw');
				return handler.process(req);
			}
		}
		
		app.use(mw);
		
		app.use('/blog', mw);
		
		app.use(Static.serve('.'));*/
		
		app.use('/:foo', function(req: IncomingRequest, next): Response {
			return 'abc';
		});
		app.route('/', function(req: Request, next): Response {
			return 'index';
		});
		
		
		
		app
		.toHandler(function (req: Request) {
			return Future.sync(('404': OutgoingResponse));
		})
		.process(new IncomingRequest('localhost', new IncomingRequestHeader(GET, '/haxelib.json', '1.1', []), IncomingRequestBody.Plain('')))
		.handle(function(res) {
			res.body.all().handle(function(b) {
				trace(b.toString());
			});
		});
	}
	
}