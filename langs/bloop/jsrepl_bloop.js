(function() {
  this.JSREPL.prototype.Engines.prototype.Bloop = (function() {
    function Bloop(input, output, result, error, sandbox, ready) {
      this.input = input;
      this.output = output;
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.sandbox.BFloop.init(this.output);
      ready();
    }
    Bloop.prototype.Eval = function(command) {
      var code;
      try {
        code = this.sandbox.BFloop.compile(command);
        return this.result(this.sandbox.eval(code));
      } catch (e) {
        return this.error(e);
      }
    };
    Bloop.prototype.GetNextLineIndent = function(command) {
      var count, match, rClose, rOpen;
      rOpen = /BLOCK\s+(\d+)\s*:\s*BEGIN/ig;
      rClose = /BLOCK\s+(\d+)\s*:\s*END/ig;
      match = function(code) {
        var closes, opens;
        opens = code.match(rOpen) || [];
        closes = code.match(rClose) || [];
        return opens.length - closes.length;
      };
      if (match(command) <= 0) {
        return false;
      } else {
        count = match(command.split('\n').slice(-1)[0]);
        if (count > 0) {
          return 1;
        } else {
          return 0;
        }
      }
    };
    return Bloop;
  })();
}).call(this);
