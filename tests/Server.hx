package;

#if !nodejs
import sys.net.Host;
import sys.net.Socket;
import sys.io.Process;
#end

class Server {
	public static var HOST = '0.0.0.0';
	public static var PORT = 2000;
	public static var ENV_NAME = 'SERVE_TEST';
	static var current: Process;
	
	public static function serve(instance: SuiteWithApp) {
		var index = RunTests.suites.indexOf(instance);
		Sys.putEnv(ENV_NAME, Std.string(index+1));
		#if php
		current = new Process('php', ['-S', '$HOST:$PORT', 'bin/php/index.php']);
		#elseif neko
		current = new Process('nekotools', ['server', '-h', HOST, '-p', '$PORT', '-rewrite', '-d', 'bin/neko/']);
		#end
		var socket = new Socket();
		var i = 0;
		while(i < 5) {
			try {
				socket.connect(new Host(HOST), PORT);
				socket.close();
				break;
			} catch(e: Dynamic) {
				Sys.print('.');
				Sys.sleep(.1);
				i++;
			}
		}
	}
	
	public static function close() {
		#if neko
		current.kill();
		#elseif php
		untyped __call__('posix_kill', current.getPid(), 9);
		#end
		//trace(current.exitCode());
	}
		
	public static function url()
		return 'http://$HOST:$PORT/';
}
