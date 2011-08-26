(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.JavaScript = (function() {
    function JavaScript(input, output, result, error, sandbox, ready) {
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.inspect = this.sandbox._inspect;
      this.functionClass = this.sandbox.Function;
      this.sandbox.__eval = this.sandbox.eval;
      this.sandbox.console.log = __bind(function(obj) {
        return output(obj + '\n');
      }, this);
      this.sandbox.console.dir = __bind(function(obj) {
        return output(this.inspect(obj) + '\n');
      }, this);
      this.sandbox.console.read = input;
      ready();
    }
    JavaScript.prototype.Eval = function(command) {
      var result;
      try {
        result = this.sandbox.__eval(command);
        return this.result(this.inspect(result));
      } catch (e) {
        return this.error(e);
      }
    };
    JavaScript.prototype.GetNextLineIndent = function(command) {
      try {
        new this.functionClass(command);
        return false;
      } catch (e) {
        if (/[\[\{\(]$/.test(command)) {
          return 1;
        } else {
          return 0;
        }
      }
    };
    return JavaScript;
  })();
}).call(this);
