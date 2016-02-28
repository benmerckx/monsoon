var hippie = require('hippie'),
	targets = ['neko', 'cpp', 'nodejs', 'mod_neko', 'php']

function time() {
	var hrTime = process.hrtime()
	return (hrTime[0] * 1000000 + hrTime[1] / 1000) / 1000
}

targets.map(function (target, index) {
	if (target == 'mod_neko') return
	console.log('Testing '+target)
	var start = time()
	hippie()
	.get('http://localhost:300'+index)
	.expectStatus(200)
	.expectBody('ok')
	.end(function(err, res, body) {
		if (err) throw err
		var end = time()-start
		console.log(target+' finished in '+Math.round(end)+'ms')
	})
})