# Monsoon

A simple router over [tink_http](https://github.com/haxetink/tink_http), based mostly 
on the [express](https://github.com/strongloop/express) api.
	
```haxe
using Monsoon;

var app = new App();

app.route('/', function (req, res) {
  res.send('Hello World');
});

app.route('/item/:id', function (req: Request<{id: Int}>, res) {
  res.send('Item id: '+req.params.id);
});

app.listen(3000);

```

## Todo

- [ ] allow path prefix for `App.use`
- [ ] add method to pass request to next route
- [ ] add `Request.sendFile`
- [ ] ensure type safety for params in macro (if path is set as constant)
- [ ] body/multipart parsing
- [ ] implement foxhole event loop for tcp
- [ ] documentation
- [ ] tests
- [ ] haxelib release