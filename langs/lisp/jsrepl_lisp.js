(function() {
  var isNil;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  isNil = function(x) {
    return (!(x != null)) || (x instanceof Array && x.length === 0);
  };
  this.JSREPL.prototype.Engines.prototype.Lisp = (function() {
    function Lisp(input, output, result, error, sandbox, ready, libs) {
      var Javathcript, f, i, load, _i, _len, _ref;
      this.error = error;
      this.sandbox = sandbox;
      Javathcript = this.Javathcript = this.sandbox.Javathcript;
      Javathcript.Environment.prototype.princ = function(obj, callback) {
        return this._value(obj, function(val) {
          output(Javathcript.environment._stringify(val));
          return callback(val);
        });
      };
      Javathcript.Environment.prototype.print = function(obj, callback) {
        return this._value(obj, function(val) {
          output(Javathcript.environment._stringify(val));
          output('\n');
          return callback(val);
        });
      };
      Javathcript.Environment.prototype.input = function(callback) {
        return input(function(str) {
          return callback(new Javathcript.Atom(str));
        });
      };
      Javathcript.Environment.prototype._error = error;
      _ref = ['princ', 'print', 'input', '_error'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        Javathcript.Environment.prototype[f].toString = function() {
          return '{library macro}';
        };
      }
      this.result_handler = function(r) {
        return result(isNil(r) ? '' : r.toString());
      };
      i = 0;
      (load = function() {
        var lib;
        if (lib = libs[i++]) {
          return Javathcript.evalMulti(lib, (function() {}), load);
        } else {
          return ready();
        }
      })();
    }
    Lisp.prototype.Eval = function(command) {
      var handleMultiResult, last_result;
      try {
        return this.Javathcript.eval(command, this.result_handler);
      } catch (e) {
        try {
          last_result = null;
          handleMultiResult = __bind(function(r) {
            return last_result = r;
          }, this);
          return this.Javathcript.evalMulti(command, handleMultiResult, __bind(function() {
            return this.result_handler(last_result);
          }, this));
        } catch (e) {
          return this.error(e.message);
        }
      }
    };
    Lisp.prototype.GetNextLineIndent = function(command) {
      var countParens, parens_in_last_line;
      countParens = __bind(function(str) {
        var assembly, parens, token, tokenizer, tokens, _i, _len;
        tokenizer = new this.Javathcript.Tokenizer(str);
        assembly = new this.Javathcript.BPWJs.TokenAssembly(tokenizer);
        tokens = assembly.tokenString.tokens;
        parens = 0;
        for (_i = 0, _len = tokens.length; _i < _len; _i++) {
          token = tokens[_i];
          if (token.ttype === 'symbol') {
            switch (token.sval) {
              case '(':
                ++parens;
                break;
              case ')':
                --parens;
            }
          }
        }
        return parens;
      }, this);
      if (countParens(command) <= 0) {
        return false;
      } else {
        parens_in_last_line = countParens(command.split('\n').slice(-1)[0]);
        if (parens_in_last_line > 0) {
          return 1;
        } else if (parens_in_last_line < 0) {
          return parens_in_last_line;
        } else {
          return 0;
        }
      }
    };
    return Lisp;
  })();
}).call(this);
