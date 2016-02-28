package;

using Monsoon;

class Run {

	public static function main() {
		var app = new Monsoon();
		app.route('/', function(req, res) res.send('ok'));
		var port = #if (sys || nodejs) Sys.args().length > 0 ? Std.parseInt(Sys.args()[0]) : 80 #else 80 #end;
		app.listen(port);
		//trace('Listening on port '+port);
	}
	
}