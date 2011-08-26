(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.Kaffeine = (function() {
    function Kaffeine(input, output, result, error, sandbox, ready) {
      var Kaffeine;
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.inspect = this.sandbox._inspect;
      this.functionClass = this.sandbox.Function;
      this.sandbox.__eval = this.sandbox.eval;
      this.tokenizer = this.sandbox.require('./token');
      Kaffeine = this.sandbox.require('./kaffeine');
      this.kaffeine = new Kaffeine;
      this.sandbox.console.log = __bind(function(obj) {
        return output(obj + '\n');
      }, this);
      this.sandbox.console.dir = __bind(function(obj) {
        return output(this.inspect(obj) + '\n');
      }, this);
      this.sandbox.console.read = input;
      ready();
    }
    Kaffeine.prototype.Eval = function(command) {
      var js;
      try {
        js = this.kaffeine.compile(command);
        try {
          new this.functionClass(js);
        } catch (e) {
          js = "(" + js + ")";
        }
      } catch (e) {
        e.message = 'Compiling: ' + e.message;
        this.error(e);
        return;
      }
      try {
        return this.result(this.inspect(this.sandbox.__eval(js)));
      } catch (e) {
        return this.error(e);
      }
    };
    Kaffeine.prototype.GetNextLineIndent = function(command) {
      var js, last_line, token;
      token = this.tokenizer.ize(command);
      while (token != null) {
        if (token.bang) {
          return 0;
        }
        token = token.next;
      }
      try {
        js = this.kaffeine.compile(command);
        try {
          new this.functionClass(js);
        } catch (e) {
          js = "(" + js + ")";
          new this.functionClass(js);
        }
        last_line = command.split('\n').slice(-1)[0];
        if (/^\s+/.test(last_line)) {
          return 0;
        } else {
          return false;
        }
      } catch (e) {
        if (/^\s*(for|while|if|else)\b|[\[\{\(]$/.test(command)) {
          return 1;
        } else {
          return 0;
        }
      }
    };
    return Kaffeine;
  })();
}).call(this);
