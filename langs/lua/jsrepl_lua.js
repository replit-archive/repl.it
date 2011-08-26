(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.Lua = (function() {
    function Lua(unused_input, output, result, error, sandbox, ready) {
      this.result = result;
      this.error = error;
      sandbox.print = (function() {});
      this.error_buffer = [];
      this.Lua = sandbox.Module.Lua;
      this.Lua.initialize(null, function(chr) {
        return output(String.fromCharCode(chr));
      }, __bind(function(chr) {
        return this.error_buffer.push(String.fromCharCode(chr));
      }, this));
      ready();
    }
    Lua.prototype.Eval = function(command) {
      var result;
      this.error_buffer = [];
      try {
        result = this.Lua.eval(command);
        if (this.error_buffer.length) {
          return this.error(this.error_buffer.join(''));
        } else {
          return this.result(result);
        }
      } catch (e) {
        return this.error(e);
      }
    };
    Lua.prototype.GetNextLineIndent = function(command) {
      if (this.Lua.isFinished(command)) {
        return false;
      } else {
        return 0;
      }
    };
    return Lua;
  })();
}).call(this);
