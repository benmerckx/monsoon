package;

import buddy.*;
import haxe.Json;
import monsoon.middleware.Compression;
import tink.http.Method;
import TestTools.*;
import TestTools.TinkResponse;
import monsoon.middleware.Static;
import tink.io.Buffer;

using Monsoon;
using buddy.Should;
using tink.CoreApi;

class TestCompression extends BuddySuite {

	public function new() {
		var app = new Monsoon();
		
        describe('Compression middleware', {
            it('should compress via gzip', function(done) {
				app.use(Compression.serve());
				app.get(function(req: Request, res: Response)
					res.html('ok')
				);
				app.serve(request('/', ['accept-encoding' => 'gzip'])).handle(function(res: TinkResponse) {
					res.header.byName('content-encoding').should.equal(Success('gzip'));
					done();
				});
			});
        });
	}
	
}