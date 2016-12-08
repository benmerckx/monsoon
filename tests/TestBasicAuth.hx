package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import monsoon.middleware.BasicAuth;
import haxe.crypto.Base64;
import haxe.io.Bytes;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestBasicAuth extends BuddySuite {

	public function new() {
		var app = new Monsoon();
		var credentials = {
			user: 'user',
			password: 'password'
		}
		
		app.use(BasicAuth.serve(function(user: String, pass: String)
			return user == credentials.user && credentials.password == pass
		));
		
		app.get('/', function(req, res: Response) 
			res.html('protected')
		);
		
        describe('BasicAuth middleware', {
			it('should request authorization', function(done) {
				app.serve(request('/')).handle(function(res: TinkResponse) {
					res.header.byName('www-authenticate').should.equal(Success('Basic realm="Authorization required"'));
					done();
				});
			});

			it('should error on incorrect credentials', function(done) {
				app.serve(request('/', [
					'authorization' => 'uh oh'
				])).handle(function(res: TinkResponse) {
					res.status.should.be(400);
					done();
				});
			});

			it('should deny access for incorrect credentials', function(done) {
				app.serve(request('/', [
					'authorization' => 'Basic '+Base64.encode(Bytes.ofString('a:b'))
				])).handle(function(res: TinkResponse) {
					res.status.should.be(401);
					done();
				});
			});

            it('should pass the route for correct credentials', function(done) {
				app.serve(request('/', [
					'authorization' => 'Basic '+Base64.encode(Bytes.ofString(credentials.user+':'+credentials.password))
				])).handle(function(res: TinkResponse) {
					res.status.should.be(200);
					res.body.should.be('protected');
					done();
				});
			});
        });
	}
	
}