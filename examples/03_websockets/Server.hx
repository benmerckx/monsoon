using Monsoon;

import monsoon.middleware.Compression;
import monsoon.middleware.Static;
import tink.protocol.websocket.Client;

class Server {
  static function main() {
    var port = 5000;
	
    var app = new Monsoon();
	
    app.use(new Compression());
    app.use(Static.serve('public'));
	
	app.route('/echo', function (req, res) {
		//new Client(
	});
	
    app.listen(port);
    trace('Server ready and listening on http://localhost:${port}');
  }
}