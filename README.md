# Monsoon

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

It is recommended to import the Monsoon classes with `using Monsoon;` at the top of your module. All routing methods are implemented as macros and will not properly function without `using`.

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

Multiple routes can be passed at once by using map notation:

```haxe
app.get([
	'/' => function (req, res) res.send('Index'),
    '/page' => function (req, res) res.send('Page')
]);
```

### Matching

#### Parameters

A segment of the path can be matched by using a `:param`. To use the parameter later in your callback, it has to be typed in the type parameter of `Request<T>`.
```haxe
app.get('/blog/:item', function(req: Request<{item: String}>, res)
	res.send('Blog item: '+req.params.item)
);
```

A parameter can be typed as `String`, `Int`, `Float` or `Bool`. The value will be parsed from the request's path, and the route is passed in case the type does not match. The following example will respond to `/blog/675`, but not to `/blog/string`.

```haxe
app.get('/blog/:id', function(req: Request<{id: Int}>, res)
	res.send('Blog item id: '+req.params.id)
);
```

#### Splat

Parameters using `:` will match anything seperated by slashes. You can match more by using an asterisk. The following example will match `/blog/a` and `/blog/a/b`. The param can remain unnamed if you don't intend on using it later (eg. `/blog/*`).

```haxe
app.get('/blog/*splat', function(req: Request<{splat: String}>, res)
	res.send('Splat: '+req.params.splat)
);
```

# Middleware

### Bundled middleware

Bundled middleware can be found in `monsoon.middleware`.

#### Body

Parses the request body to string. The resulting instance has a `toString()` method so you can use the body. A `toMap()` method is also supplied for parsing key value pairs (eg. form submission).   
The middleware (and any other) can be injected into a route simply by adding it to the callback's arguments:

```haxe
app.post('/submit', function(req, res, body: Body)
	res.send('Post body content '+body);
);
```

#### Static

The static middleware can be used to serve static files (js, css, html etc.). It is recommended to use seperate software (nginx, varnish) to serve your static files but this can be used during development or on low traffic websites.

If a file is found it will be served with the correct content-type. If no file is found the route is passed.

```haxe
// Any file in the public folder will be served
app.route(Static.serve('public')); 
// You can change the index files it looks for (default is index.html, index.htm)
app.route(Static.serve('public', {index: ['index.txt', 'index.html']})); 
// It can be prefixed like any other route
app.route('/assets', Static.serve('public')); 
```

#### Console

The Console is a debugging tool which will bundle any traces created during the processing of the request and send them with your response to the browser. They are packaged as a single `<script>` tag and log to the console on the client side.   
Middleware can used for all matching requests in the current router by passing the Class as you would a callback:


```haxe
app.route(Console); // Is the same as app.route('*', Console);
```

![Console](https://github.com/benmerckx/monsoon/blob/master/docs/console.png?raw=true "")

### Writing your own

Middleware is defined as one of these forms:
```haxe
interface ConfigurableMiddleware {public function setRouter(router: Router): Void;}
typedef Middleware = {public function new(router: Router): Void;}
```

The router argument can be used the route any request (it defines the same http methods for routing).

Middleware can be used to create controllers. A very simple example:

```haxe
class Blog {
	public function new(router: Router) {
    	router.get([
        	'/' => index,
            '/:item' => detail
        ]);
    }
    
    function index(request: Request, response: Response)
    	response.send('List blog items');
        
    function detail(request: Request<{item: String}>, response: Response)
    	response.send('Print blog detail');
}

// Somewhere else:

app.route([
	'/blog' => Blog
]);

// This will serve /blog as index and /blog/item-title as detail
```


# Request

```haxe
class Request<T> {
	// Any parameters that were requested in the callback
	var params: T;
    // Full url (eg. /page?query=1)
	var url: String;
    // Path only, stripped of query (eg. /page)
	var path: String;
    // The http request method (see monsoon.Method)
	var method: Method;
    // The hostname if it was set in the request headers
	var hostname: Null<String>;
    // IP of the client that made the request
	var ip: String;
    // Holds all query values (eg. {query => 1})
	var query: Map<String, String>;

	// Use in a callback to pass this request to the next route
	function next();
    // Returns a printable representation of the request
	function toString();
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
	function json(output: Dynamic, ?space): Response;
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


# App options

Following options can be supplied when creating a new `Monsoon` instance:
 - `threads`: Int - amount of threads to use for the embedded webserver
 - `watch`: Bool - currently only supported on neko, exits the webserver when the .n file changes ([see also](https://github.com/back2dos/foxhole/#watch-mode))

	 

License: MIT