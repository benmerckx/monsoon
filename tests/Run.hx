package;

using Monsoon;

class Run {

	public static function main() {
		var app = new Monsoon();
		app.route('/', function(req, res) res.send('ok'));
		app.listen(#if (embed && neko) 3000 #elseif cpp 3001 #elseif nodejs 3002 #end);
	}
	
}