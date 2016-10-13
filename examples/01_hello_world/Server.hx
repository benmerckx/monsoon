using Monsoon;

class Server {
  public static function main() {
    var app = new Monsoon();

    app.route('/', function (req, res)
      res.send('Hello World')
    );

    app.listen(3000);
  }
}