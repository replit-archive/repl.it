(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.Unlambda = (function() {
    function Unlambda(input, output, result, error, sandbox, ready) {
      this.input = input;
      this.output = output;
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.Unlambda = this.sandbox.Unlambda;
      this.result = __bind(function(value) {
        return result(this.Unlambda.unparse(value));
      }, this);
      ready();
    }
    Unlambda.prototype.Eval = function(command) {
      var parsed;
      try {
        parsed = this.Unlambda.parse(command);
      } catch (e) {
        this.error(e);
        return;
      }
      return this.Unlambda.eval(parsed, this.result, this.input, this.output, this.error);
    };
    Unlambda.prototype.GetNextLineIndent = function(command) {
      if (/`$/.test(command)) {
        return 0;
      }
      try {
        this.Unlambda.parse(command);
        return false;
      } catch (e) {
        return 0;
      }
    };
    return Unlambda;
  })();
}).call(this);
