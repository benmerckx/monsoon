# Monsoon

A simple router over [tink_http](https://github.com/haxetink/tink_http), based mostly 
on the [express](https://github.com/strongloop/express) api.
	
```haxe
using Monsoon;

var app = new Monsoon();

app.route('/', function (req, res) {
  res.send('Hello World');
});

app.route('/item/:id', function (req: Request<{id: Int}>, res) {
  res.send('Item id: '+req.params.id);
});

app.listen(3000);

```

## Todo

- [ ] allow path prefix for `Monsoon.use`
- [x] add method to pass request to next route
- [x] body parsing
- [ ] multipart parsing
- [x] implement foxhole event loop for tcp
- [ ] proper error reporting
- [ ] documentation
- [ ] tests
- [ ] haxelib release