var hippie = require('hippie'),
	spawn = require('child_process').spawn,
	port = 4000,
	targets = [
		{
			name: 'neko', 
			process: function(port) {return spawn('neko', ['bin/neko/index.n', port])}
		}, 
		{
			name: 'cpp', 
			process: function(port) {return spawn('./bin/cpp/Run', [port])}
		},
		{
			name: 'nodejs', 
			process: function(port) {return spawn('node', ['bin/node/index.js', port])}
		},
		{
			name: 'java', 
			process: function(port) {return spawn('java', ['-jar', 'bin/java/Run.jar', port])}
		},
		{
			name: 'mod_neko', 
			process: function(port) {return spawn('nekotools', ('server -h 0.0.0.0 -rewrite -p '+port+' -d bin/mod_neko').split(' '))}
		},
		{
			name: 'php', 
			process: function(port) {return spawn('php', ('-S 0.0.0.0:'+port+' -file bin/php/index.php').split(' '))}
		}
	],
	todo = 0

console.log(__dirname)
process.chdir(__dirname)

function time() {
	var hrTime = process.hrtime()
	return (hrTime[0] * 1000000 + hrTime[1] / 1000) / 1000
}

function logProgress(data) {
	var str = data.toString(), 
	lines = str.split(/(\r?\n)/g)
	console.log(lines.join(""))
}

function functionName(fun) {
	var ret = fun.toString()
	ret = ret.substr('function '.length)
	ret = ret.substr(0, ret.indexOf('('))
	return ret
}

function setup(port) {
	todo++
	return hippie().base('http://0.0.0.0:'+port).timeout(600)
}

var tests = [
	function testBase(api) {
		return api.get('/').expectStatus(200).expectBody('ok')
	},
	function testArgString(api) {
		return api.json().get('/arg/string').expectBody({arg: 'string'})
	},
	function testArgInt(api) {
		return api.json().get('/arg/123').expectBody({arg: 123})
	},
	function testMiddleware(api) {
		return api.post('/post').send('postbody').expectBody(JSON.stringify({body: 'postbody'}))
	},
	function testCookie(api) {
		return api.get('/cookie').expectHeader('set-cookie', ['name=value;'])
	},
	function testController(api) {
		return api.json().get('/controller').expectBody({route: 'controller_index'})
	},
	function testControllerPath(api) {
		return api.json().get('/controller/path').expectBody({route: 'controller_path'})
	},
	function testStatic(api, target) {
		if (['php', 'mod_neko'].indexOf(target) > -1)
			return null
		return api.get('/public/plain.txt').expectHeader('content-type', 'text/plain').expectBody('plain')
	},
	function testStaticIndex(api, target) {
		if (['php', 'mod_neko'].indexOf(target) > -1)
			return null
		return api.get('/public/').expectHeader('content-type', 'text/html').expectBody('index')
	}
]

targets.map(function (target, index) {
	
	(function(port) {
		var child = target.process(port).on('error', console.log)
		child.stderr.on('data', logProgress)
		if (target.name != 'mod_neko')
			child.stdout.on('data', logProgress)

		setTimeout(function() {
			var start = time(), 
				todo = 0, 
				done = 0, 
				failed = 0
				
			tests.map(function (f) {
				todo++
				setTimeout(function() {
					var test = f(setup(port), target.name)
					if (test == null) {
						todo--
						return
					}
					test.end(function(err, res, body) {
						if (err) {
							failed++
							console.log(target.name+' failed '+functionName(f)+': \n'+err)
						}
						done++
						if (todo === done) {
							var end = time()-start
							console.log(target.name+' passed '+(todo-failed)+'/'+todo+' tests in '+Math.round(end)+'ms')
							child.kill()
						}
					})
				}, 0)
			})
		}, 200)
	})(port++)
	
})