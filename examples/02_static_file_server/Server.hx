using Monsoon;

import monsoon.middleware.Static;

class Server {
  static function main() {
    var port = 5000;
    var app = new Monsoon();
    app.use(Static.serve('public'));
    app.listen(port);
    trace('Server ready and listening on http://localhost:${port}');
  }
}