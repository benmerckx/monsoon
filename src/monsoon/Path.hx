package monsoon;

abstract Path(String) from (String) {
	public static inline var IDENTIFIER = ':';
	
	inline public function getParamNames() {
		return this
		.split('/')
		.filter(function(segment) return segment.charAt(0) == IDENTIFIER)
		.map(function(segment) return segment.substr(1));
	}
}