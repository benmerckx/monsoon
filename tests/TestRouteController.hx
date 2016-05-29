package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestRouteController extends BuddySuite {

	public function new() {
        describe('RouteController', {
			it('app.use should accept RouteController', function(done) {
				var app = new Monsoon();
				app.use(this);
				app.serve(request('/')).handle(function(res: TinkResponse) {
					res.body.should.be('ok');
					done();
				});
			});
			
			it('app.use should accept a prefix', function(done) {
				var app = new Monsoon();
				app.use('/prefix', this);
				app.serve(request('/prefix')).handle(function(res: TinkResponse) {
					res.body.should.be('ok');
					done();
				});
			});
			
			it('app.use should accept multiple prefixes', function(done) {
				var app = new Monsoon();
				app.use('/prefix', this);
				app.serve(request('/prefix/double')).handle(function(res: TinkResponse) {
					res.body.should.be('ok');
					done();
				});
			});
			
			it('app.use should change the request path', function(done) {
				var app = new Monsoon();
				app.use('/prefix', function(req: Request, res: Response) {
					req.path.should.be('abc');
					res.end();
				});
				app.use(function(req: Request, res: Response) {
					req.path.should.be('abc');
					res.end();
				});
				Future.ofMany([
					app.serve(request('/prefix/abc')),
					app.serve(request('/abc'))
				]).handle(function(_) done());
			});
        });
	}
	
	public function createRoutes(router: Router) {
		router.route([
			'/' => function(req, res) res.send('ok')
		]);
		router.use('/double', this);
	}
	
}