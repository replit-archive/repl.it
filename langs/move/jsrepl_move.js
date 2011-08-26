(function() {
  var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.Move = (function() {
    function Move(input, output, result, error, sandbox, ready) {
      var func, name, _ref;
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.inspect = this.sandbox._inspect;
      this.functionClass = this.sandbox.Function;
      this.sandbox.__eval = this.sandbox.eval;
      this.compile = this.sandbox.move.compile;
      this.sandbox.move.runtime.print = __bind(function() {
        var objs;
        objs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return output(objs.join(' ') + '\n');
      }, this);
      this.sandbox.move.runtime.read = input;
      _ref = this.sandbox.move.runtime;
      for (name in _ref) {
        func = _ref[name];
        this.sandbox[name] = func;
      }
      ready();
    }
    Move.prototype.Eval = function(command) {
      var js;
      command = '#pragma enable ehtml\n' + command;
      try {
        js = this.compile(command, {
          strict: true,
          raw: true
        });
        return this.result(this.inspect(this.sandbox.__eval(js)));
      } catch (e) {
        return this.error(e);
      }
    };
    Move.prototype.GetNextLineIndent = function(command) {
      var last_line;
      command = '#pragma enable ehtml\n' + command;
      try {
        new this.functionClass(this.compile(command, {
          strict: true,
          raw: true
        }));
        last_line = command.split('\n').slice(-1)[0];
        if (/^\s+/.test(last_line)) {
          return 0;
        } else {
          return false;
        }
      } catch (e) {
        if (/[\[\{\(]$/.test(command)) {
          return 1;
        } else {
          return 0;
        }
      }
    };
    return Move;
  })();
}).call(this);
