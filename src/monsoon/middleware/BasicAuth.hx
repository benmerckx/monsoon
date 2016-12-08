package monsoon.middleware;

import haxe.crypto.Base64;

using tink.CoreApi;
using StringTools;

class BasicAuth {

	static var SHEME = 'Basic ';
	
	public static function serve(validate: String -> String -> Promise<Bool>, realm = 'Authorization required')
		return function(req: Request, res: Response, next: Void -> Void) {
			inline function auth() {
				res.status(401)
				.set('www-authenticate', 'Basic realm="${realm.split('"').join('\"')}"')
				.end();
			}
			var authorization = req.get('authorization');
			if (authorization == null) {
				return auth();
			} else {
				if (!authorization.startsWith(SHEME))
					return res.error(400, 'Malformed authorization header');
				var encoded = authorization.substr(SHEME.length);
				var decoded = Base64.decode(encoded).toString().split(':');
				var user = decoded[0], pass = decoded[1];
				if (pass == null) return res.error(400, 'Malformed authorization header');
				validate(user, pass).handle(function (result)
					switch result {
						case Success(valid):
							if (valid) next();
							else auth();
						case Failure(msg):
							res.error('$msg');
					}
				);
			}
		}
	
}