package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import monsoon.middleware.Body;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestBody extends BuddySuite {

	public function new() {
		var app = new Monsoon();
		
        describe('Body middleware', {
            it('can be injected in a callback', function(done) {
				app.route(function(req: Request, res: Response, body: Body) {
					res.send(body.toString());
				});
				app.serve(request(POST, '/', 'body')).handle(function(res: TinkResponse) {
					res.body.should.be('body');
					done();
				});
			});
        });
	}
	
}