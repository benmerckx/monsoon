# Monsoon [![Build Status](https://travis-ci.org/benmerckx/monsoon.svg?branch=master)](https://travis-ci.org/benmerckx/monsoon)

A minimal haxe web framework and embedded webserver using [tink_http](https://github.com/haxetink/tink_http).

```haxe
using Monsoon;

class Main {
  public static function main() {
    var app = new Monsoon();

    app.route('/', function (req, res)
      res.send('Hello World')
    );

    app.listen(3000);
  }
}

```

# Setup

Choose a target and lib of one of the implementations below.

### Default

Monsoon runs on platforms that provide their own http implementation.  
Runs on: `nodejs`, `php`, `neko` *(mod_neko, mod_tora)*
```
haxelib install monsoon
```
*Add `-lib monsoon` to your hxml.*

### Embedded

A tcp webserver will be embedded into your application.  
Runs on: `neko`, `cpp`, `java`
```
haxelib install monsoon-embed
```
*Add `-lib monsoon-embed` to your hxml.*

### Usage

You can import all relevant classes with `using Monsoon;`.

# Routing

### Basic routing

The following http request methods can be used to add routes to your app:  
`get`, `post`, `delete`, `put`, `patch`, `head`, `options`

```haxe
app.get('/', function (req, res) res.send('Get'));
app.post('/submit', function (req, res) res.send('Got post'));
```

To match all http methods use `route`

```haxe
app.route('/', function (req, res) 
	res.send('Method used: '+req.method)
);
```

### Matching

Matching is done using [a port](https://github.com/benmerckx/path2ereg) of [path-to-regex](https://github.com/pillarjs/path-to-regexp).
You can refer to the [express docs](https://expressjs.com/en/guide/routing.html#route-paths) on routing and test the rules with [Express Route Tester](http://forbeslindesay.github.io/express-route-tester/).

#### Parameters

A segment of the path can be matched by using a `:param`. To use the parameter later in your callback, it has to be typed in the type parameter of `Request<T>`.
```haxe
app.get('/blog/:item', function(req: Request<{item: String}>, res)
	res.send('Blog item: '+req.params.item)
);
```

# Middleware

### Bundled middleware

Bundled middleware can be found in `monsoon.middleware`.

#### Compression

Compresses the result of your response using gzip, if accepted by the client.
Takes one optional argument: `?level: Int`, the compression level of 0-9.

```haxe
app.use(new Compression());
```

#### Static

The static middleware can be used to serve static files (js, css, html etc.). It is recommended to use seperate software (nginx, varnish) to serve your static files but this can be used during development or on low traffic websites.

If a file is found it will be served with the correct content-type. If no file is found the route is passed.

```haxe
// Any file in the public folder will be served
app.use(Static.serve('public')); 
// You can change the index files it looks for (default is index.html, index.htm)
app.use(Static.serve('public', {index: ['index.txt', 'index.html']})); 
// It can be prefixed like any other route
app.use('/assets', Static.serve('public')); 
```

#### ByteRange

Supports client requests for ranged responses.
	
```haxe
app.use(ByteRange.serve);
```

#### Console

The Console is a debugging tool which will bundle any traces created during the processing of the request and send them with your response to the browser. They are packaged as a single `<script>` tag and log to the console on the client side.   
Middleware can used for all matching requests in the current router by passing the Class as you would a callback:


```haxe
app.use(new Console());
```

![Console](https://github.com/benmerckx/monsoon/blob/master/docs/console.png?raw=true "")

# Request

```haxe
class Request<T> {
	// Any parameters that were requested in the callback
	var params: T;
    // Full url (eg. /page?query=1)
	var url: Url;
    // Path only, stripped of query (eg. /page)
	var path: String;
    // The http request method
	var method: Method;
	// The request body, plain or parsed (see tink.http)
	var body: IncomingRequestBody;
    // The hostname if it was set in the request headers
	var hostname: Null<String>;
    // IP of the client that made the request
	var ip: String;
    // Holds all query values (eg. {query => 1})
	var query: Map<String, String>;
    // All cookies sent with this request
	var cookies: Map<String, String>;

	// Returns the specified HTTP request header field
	function get(key: String): Null<String>;
}
```

# Response

```haxe
class Response {
	// Set the http status code (defaults to 200)
	function status(code: Int): Response;
	// Clear all set headers, cookies and the status code
	function clear(): Response;
	// Set a cookie, see monsoon.Response.CookieOptions
	function cookie(name: String, value: String, ?options: CookieOptions): Response;
	// Sets 'Content-Type' to 'application/json' and sends output as json
	function json(output: Dynamic, ?space: String): Response;
	// Set a header
	function set(key: String, value: String): Response;
	// Get a previously set header, or null if not set
	function get(key: String): Null<String>;
	// Redirect to a location, sets 'Location' header
	function redirect(code = 302, url: String);
	// Sets 'Content-Type' to 'text/plain' and sends output with error code
	function error(code = 500, message: String);
	// End this response without a body
	function end();
	// End the response with given output
	function send(output: String);
	// End the response with the file's contents, content-type will be set automatically but can be set explicitly
	function sendFile(path: String, ?contentType: String)
}
```	 

License: MIT