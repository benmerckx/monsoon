class Forever {
  static function main() {
    var args = Sys.args();
    while (true) {
      Sys.command(args[0], args.slice(1));
      Sys.sleep(.25);
    }
  }
}