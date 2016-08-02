package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import haxe.DynamicAccess;

using Monsoon;
using buddy.Should;

class TestRouter extends BuddySuite {
    public function new() {
		var app = new Monsoon();
        describe('Router', {
            it('should serve requests', function(done) {
				app.get('/', function(req, res) res.send('hello'));
				app.serve(request('/')).handle(function(res: TinkResponse) {
					res.status.should.be(200);
					res.body.should.be('hello');
					done();
				});
			});
			
			it('should parse params', function(done) {
				app.get('/param/:arg', function(req: Request<{arg: String}>, res: Response) 
					res.json({param: req.params.arg})
				);
				app.serve(request('/param/string')).handle(function(res: TinkResponse) {
					res.body.should.be(Json.stringify({param: 'string'}));
					done();
				});
			});
			
			it('should parse params of different types', function(done) {
				app.get('/arg/:arg', function(req: Request<{arg: Int}>, res: Response) res.send('Int: '+req.params.arg));
				app.get('/arg/:arg', function(req: Request<{arg: Float}>, res: Response) res.send('Float: '+req.params.arg));
				
				app.serve(request(GET, '/arg/123')).handle(function(res: TinkResponse) {
					res.body.should.be('Int: 123');
					app.serve(request(GET, '/arg/12.05')).handle(function(res: TinkResponse) {
						res.body.should.be('Float: 12.05');
						done();
					});
				});
			});
			
			it('should parse bool param');
			
			it('should parse splat', function(done) {
				app.get('/splat/*', function(req: Request<DynamicAccess<String>>, res: Response) 
					res.json({splat: req.params.get('0')})
				);
				app.serve(request('/splat/more/than/one/dir')).handle(function(res: TinkResponse) {
					res.body.should.be(Json.stringify({splat: 'more/than/one/dir'}));
					done();
				});
			});
			
			it('should respond with 404 if a page is not found', function(done) {
				app.serve(request('/unknown')).handle(function(res: TinkResponse) {
					res.status.should.be(404);
					done();
				});
			});
			
			it('should respond a server error if something goes wrong', function(done) {
				app.get('/fail', function(req: Request, res: Response) 
					throw 'fail'
				);
				app.serve(request('/fail')).handle(function(res: TinkResponse) {
					res.status.should.be(500);
					done();
				});
			});
        });
	}
}