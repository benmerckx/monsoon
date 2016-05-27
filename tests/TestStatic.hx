package;

import buddy.*;
import haxe.Json;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import monsoon.middleware.Static;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestStatic extends BuddySuite {

	public function new() {
		var app = new Monsoon();
		
        describe('Static middleware', {
            it('should serve files', function(done) {
				app.use(Static.serve('/'));
				app.serve(request('/README.md')).handle(function(res: TinkResponse) {
					res.status.should.be(200);
					done();
				});
			});
			
			it('should serve index files for a directory');
        });
	}
	
}