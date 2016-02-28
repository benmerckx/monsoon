package;

using Monsoon;

class Run {

	public static function main() {
		var app = new Monsoon();
		app.route('/', function(req, res) res.send('ok'));
		app.listen();
	}
	
}