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
			name: 'mod_neko', 
			process: function(port) {return spawn('nekotools', ('server -rewrite -p '+port+' -d bin/mod_neko').split(' '))}
		},
		{
			name: 'php', 
			process: function(port) {return spawn('php', ('-S 0.0.0.0:'+port+' -file bin/php/index.php').split(' '))}
		}
	]

function time() {
	var hrTime = process.hrtime()
	return (hrTime[0] * 1000000 + hrTime[1] / 1000) / 1000
}

function logProgress(data) {
	var str = data.toString(), 
	lines = str.split(/(\r?\n)/g)
	console.log(lines.join(""))
}

targets.map(function (target, index) {
	console.log('Testing '+target.name)
	port++

	(function(port) {
		var child = target.process(port)

		setTimeout(function() {
			var start = time()
			child.on('error', (err) => console.log(err))
			//child.stderr.on('data', logProgress)
			//child.stdout.on('data', logProgress)

			hippie()
			.get('http://localhost:'+port)
			.expectStatus(200)
			.expectBody('ok')
			.end(function(err, res, body) {
				if (err) {
					child.kill()
					console.log(target.name+' failed: '+err)
					return
				}
				var end = time()-start
				console.log(target.name+' finished in '+Math.round(end)+'ms')
				child.kill()
			})
		}, 100)
	})(port)
})