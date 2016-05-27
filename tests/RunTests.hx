package;

import buddy.reporting.ConsoleColorReporter;
import buddy.SuitesRunner;
import haxe.Http;
import tink.http.Header;
import tink.http.Method;
import tink.http.Request.IncomingRequest;
import tink.http.Request.IncomingRequestHeader;
import tink.http.Response.OutgoingResponse;
import tink.io.Buffer;

using Monsoon;
using buddy.Should;

class RunTests {
	public static var suites: Array<SuiteWithApp> = [
		new Test()
	];
	
	public static function main() {
		/*#if (neko || php)
		var index = Std.parseInt(Sys.getEnv(Server.ENV_NAME));
		if (index > 0) {
			suites[index-1].app.listen();
			return;
		}
		#end*/
		var reporter = new ConsoleColorReporter();
		var runner = new SuitesRunner(suites, reporter);
		runner.run();
    }
}

class Test extends SuiteWithApp {
    public function new() {
		app = new Monsoon();
		app.get('/', function(req, res) res.send('hello'));
		app.get('/test', function(req, res) res.send('test'));
		
        describe("Using Buddy", {
			//beforeAll(Server.serve(this));
			
            it("should serve requests", function(done) {
				var req = new IncomingRequest('127.0.0.1', new IncomingRequestHeader(tink.http.Method.GET, '/', '1.1', []), null);
				app.serve(req).handle(function(res: OutgoingResponse) {
					var buffer = Buffer.alloc();
					res.body.read(buffer);
					buffer.content().toString().should.be('hello');
					done();
				});
			});
			
			//afterAll(Server.close());
        });
	}
}