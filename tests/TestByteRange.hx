package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import monsoon.middleware.ByteRange;
import monsoon.middleware.Static;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestByteRange extends BuddySuite {

	public function new() {
		var app = new Monsoon();
		
		app.use(ByteRange.serve);
		app.get('/', function(req, res: Response) 
			res.set('content-length', '10').send('0123456789')
		);
		
        describe('Range middleware', {
            it('should set the accept-ranges header', function(done) {
				app.serve(request('/')).handle(function(res: TinkResponse) {
					res.header.byName('accept-ranges').should.equal(Success('bytes'));
					done();
				});
			});
			
			it('should serve 0-end range', function(done) {
				app.serve(request('/', ['range' => 'bytes=0-3'])).handle(function(res: TinkResponse) {
					res.status.should.be(206);
					res.header.byName('content-length').should.equal(Success('4'));
					res.header.byName('content-range').should.equal(Success('bytes 0-3/10'));
					res.body.should.be('0123');
					done();
				});
			});
			
			it('should serve start-end range', function(done) {
				app.serve(request('/', ['range' => 'bytes=1-4'])).handle(function(res: TinkResponse) {
					res.status.should.be(206);
					res.header.byName('content-length').should.equal(Success('4'));
					res.header.byName('content-range').should.equal(Success('bytes 1-4/10'));
					res.body.should.be('1234');
					done();
				});
			});
			
			it('should serve start- range', function(done) {
				app.serve(request('/', ['range' => 'bytes=8-'])).handle(function(res: TinkResponse) {
					res.status.should.be(206);
					res.header.byName('content-length').should.equal(Success('2'));
					res.header.byName('content-range').should.equal(Success('bytes 8-9/10'));
					res.body.should.be('89');
					done();
				});
			});
			
			it('should serve -end range', function(done) {
				app.serve(request('/', ['range' => 'bytes=-2'])).handle(function(res: TinkResponse) {
					res.status.should.be(206);
					res.header.byName('content-length').should.equal(Success('2'));
					res.header.byName('content-range').should.equal(Success('bytes 8-9/10'));
					res.body.should.be('89');
					done();
				});
			});
			
			it('should fail on incorrect ranges', function(done) {
				app.serve(request('/', ['range' => 'bytes=0-11'])).handle(function(res: TinkResponse) {
					res.status.should.be(416);
					done();
				});
			});
        });
	}
	
}