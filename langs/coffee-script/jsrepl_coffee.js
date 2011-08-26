(function() {
  var SCOPE_OPENERS;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  SCOPE_OPENERS = ['FOR', 'WHILE', 'UNTIL', 'LOOP', 'IF', 'POST_IF', 'SWITCH', 'WHEN', 'CLASS', 'TRY', 'CATCH', 'FINALLY'];
  this.JSREPL.prototype.Engines.prototype.CoffeeScript = (function() {
    function CoffeeScript(input, output, result, error, sandbox, ready) {
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.inspect = this.sandbox._inspect;
      this.CoffeeScript = this.sandbox.CoffeeScript;
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
    CoffeeScript.prototype.Eval = function(command) {
      var compiled, result;
      try {
        compiled = this.CoffeeScript.compile(command, {
          globals: true,
          bare: true
        });
        result = this.sandbox.__eval(compiled, {
          globals: true,
          bare: true
        });
        return this.result(this.inspect(result));
      } catch (e) {
        return this.error(e);
      }
    };
    CoffeeScript.prototype.GetNextLineIndent = function(command) {
      var all_tokens, index, last_line, last_line_tokens, next, scopes, token, _i, _len, _len2, _ref;
      last_line = command.split('\n').slice(-1)[0];
      if (/([-=]>|[\[\{\(]|\belse)$/.test(last_line)) {
        return 1;
      } else {
        try {
          all_tokens = this.CoffeeScript.tokens(command);
          last_line_tokens = this.CoffeeScript.tokens(last_line);
        } catch (e) {
          return 0;
        }
        try {
          this.CoffeeScript.compile(command);
          if (/^\s+/.test(last_line)) {
            return 0;
          } else {
            for (index = 0, _len2 = all_tokens.length; index < _len2; index++) {
              token = all_tokens[index];
              next = all_tokens[index + 1];
              if (token[0] === 'REGEX' && token[1] === '/(?:)/' && next[0] === 'MATH' && next[1] === '/') {
                return 0;
              }
            }
            return false;
          }
        } catch (e) {
          scopes = 0;
          for (_i = 0, _len = last_line_tokens.length; _i < _len; _i++) {
            token = last_line_tokens[_i];
            if (_ref = token[0], __indexOf.call(SCOPE_OPENERS, _ref) >= 0) {
              scopes++;
            } else if (token.fromThen) {
              scopes--;
            }
          }
          if (scopes > 0) {
            return 1;
          } else {
            return 0;
          }
        }
      }
    };
    return CoffeeScript;
  })();
}).call(this);
