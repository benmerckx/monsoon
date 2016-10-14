package monsoon.middleware;

import httpstatus.HttpStatusMessage;
import tink.io.Buffer;
import tink.io.Source;
import tink.io.IdealSink.BlackHole;
import haxe.io.Bytes;
import tink.io.StreamParser;

using tink.CoreApi;

typedef Range = {
	start: Int,
	length: Int
}

class ByteRange {
	
	static var HEADER_START = 'bytes=';
	
	static function bytePos(input: String): Option<Int> {
		if (input == '') return None;
		var number = Std.parseInt(input);
		if (number == null) return None;
		return Some(number);
	}
	
	static function parseRange(header: String, length: Int): Outcome<Array<Range>, Noise> {
		if (header.substr(0, HEADER_START.length) != HEADER_START)
			return Failure(Noise);
			
		var ranges = header.substr(HEADER_START.length).split(','),
			response = [];
		for (range in ranges) {
			var parts = range.split('-');
			if (parts.length != 2)
				return Failure(Noise);
			
			switch [bytePos(parts[0]), bytePos(parts[1])] {
				case [Some(start), Some(end)]:
					response.push({start: start, length: (end-start)+1});
				case [Some(start), None]:
					response.push({start: start, length: length-start});
				case [None, Some(end)]:
					response.push({start: length-end, length: end});
				default:
					return Failure(Noise);
			}
		}
		return Success(response);
	}

	public static function serve(req: Request, res: Response, next: Void -> Void) {
		function done()
			return Future.sync(res);
			
		function fail() {
			res.error(416, HttpStatusMessage.fromCode(416));
			return Future.sync(res);
		}
			
		res.after(function (res) {
			if (res.get('content-length') == null) 
				return done();
			
			var length = Std.parseInt(res.get('content-length'));
			res.set('accept-ranges', 'bytes');
			
			var header = req.get('range');
			if (header == null)
				return done();
				
			switch parseRange(req.get('range'), length) {
				case Success(ranges):
					if (ranges.length != 1)
						return fail();
					var range = ranges[0];
					if (range.start+range.length > length)
						return fail();
					
					var body: Source = res.body;
					if (range.start > 0) {
						var limited = body.limit(range.start);
						limited.pipeTo(BlackHole.INST);
					}
							
					@:privateAccess
					res.body = body.limit(range.length).idealize(fail);
					
					res
					.status(206)
					.set('content-length', '${range.length}')
					.set('content-range', 'bytes ${range.start}-${range.start+range.length-1}/${length}');
					
					return done();
				default:
					return fail();
			}
			
			return done();
		});
		
		next();
	}
	
}