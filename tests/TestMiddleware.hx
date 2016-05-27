package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestMiddleware extends BuddySuite {

	public function new() {
        describe('Middleware', {
            it('app.use should accept Request -> Response -> Void', function(done) {
				var app = new Monsoon();
				app.use(setTestHeader);
				app.route('/', function(req, res) res.end());
				app.serve(request('/')).handle(function(res: TinkResponse) {
					res.header.byName('test').should.equal(Success('ok'));
					done();
				});
			});
			
			it('app.use should accept Middleware', function(done) {
				var app = new Monsoon();
				app.use({
					process: setTestHeader
				});
				app.route('/', function(req, res) res.end());
				app.serve(request('/')).handle(function(res: TinkResponse) {
					res.header.byName('test').should.equal(Success('ok'));
					done();
				});
			});
        });
	}
	
	function setTestHeader(req: Request, res: Response) {
		res.set('test', 'ok');
		req.next();
	}
	
}