package;

import buddy.*;
import haxe.EnumTools;
import haxe.Json;
import tink.http.Header.HeaderField;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestRequest extends BuddySuite {
    public function new() {
		var app = new Monsoon();
        describe('Request', {
            it('should contain the http method', function(done) {
				app.route('/http-method/:method', function(req: Request<{method: String}>, res: Response) {
					req.method.should.be(req.params.method.toUpperCase());
					res.end();
				});
				
				Future.ofMany(
					[GET, HEAD, OPTIONS, POST, PUT, PATCH, DELETE].map(function (m)
						return app.serve(request(m, '/http-method/'+(m: String).toLowerCase()))
					)
				).handle(function(_) done());
			});
			
			it('should parse query parameters', function(done) {
				app.route('/parse-query', function(req: Request, res: Response) {
					req.query.get('a').should.be('1');
					req.query.get('b').should.be('2');
					res.end();
				});
				
				app.serve(request('/parse-query?a=1&b=2')).handle(function(_) done());
			});
			
			it('should parse cookies', function(done) {
				var value = 'testvalue#é_$<>Ϸ';
				app.route('/cookies', function(req: Request, res: Response) {
					req.cookies.get('name').should.be(value);
					res.end();
				});
				app.serve(request('/cookies', ['set-cookie' => 'name='+StringTools.urlEncode(value)])).handle(function(_) done());
			});
			
			it('should parse multiple cookies');
			
			it('should get client headers', function(done) {
				app.route('/client-headers', function(req: Request, res: Response) {
					req.get('x-test-header').should.be('ok');
					req.get('unknown').should.be(null);
					res.end();
				});
				app.serve(request('/client-headers', ['x-test-header' => 'ok'])).handle(function(_) done());
			});
			
        });
	}
}