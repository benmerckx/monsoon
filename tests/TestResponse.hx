package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import asys.FileSystem;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestResponse extends BuddySuite {
    public function new() {
		var app = new Monsoon();
        describe('Response', {
			it('should send a response body', function(done) {
				app.get('/response', function(req, res) res.send('ok'));
				app.serve(request('/response')).handle(function(res: TinkResponse) {
					res.status.should.be(200);
					res.body.should.be('ok');
					done();
				});
			});
			
            it('should set the status', function(done) {
				app.get('/status', function(req, res) res.status(600).end());
				app.serve(request('/status')).handle(function(res: TinkResponse) {
					res.status.should.be(600);
					done();
				});
			});
			
			it('should respond json', function(done) {
				var obj = {test: '123'};
				app.get('/json', function(req, res: Response) res.json(obj));
				app.serve(request('/json')).handle(function(res: TinkResponse) {
					res.header.byName('content-type').should.equal(Success('application/json'));
					res.body.should.be(Json.stringify(obj));
					done();
				});
			});
			
			it('should set headers', function(done) {
				app.get('/set-headers', function(req, res: Response) 
					res.set('x-test', 'abc').set('x-more', '123').end()
				);
				app.serve(request('/set-headers')).handle(function(res: TinkResponse) {
					res.header.byName('x-test').should.equal(Success('abc'));
					res.header.byName('x-more').should.equal(Success('123'));
					done();
				});
			});
			
			it('should create proper error responses', function(done) {
				app.get('/error', function(req, res: Response) 
					res.error(500, 'failed')
				);
				app.serve(request('/error')).handle(function(res: TinkResponse) {
					res.status.should.be(500);
					res.body.should.be('failed');
					done();
				});
			});
			
			it('should serve files with content-type and content-length', function(done) {
				var file = 'haxelib.json';
				FileSystem.stat(file).handle(function (res) switch res {
					case Success(stat):
						app.get('/file', function(req, res: Response) res.sendFile('haxelib.json'));
						app.serve(request('/file')).handle(function(res: TinkResponse) {
							res.header.byName('content-type').should.equal(Success('application/json; charset=utf-8'));
							res.header.byName('content-length').should.equal(Success('${stat.size}'));
							done();
						});
					default:
						fail('Could not read haxelib.json');
				});
			});
        });
	}
}