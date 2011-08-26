(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.Scheme = (function() {
    function Scheme(input, output, result, error, sandbox, ready) {
      var Port;
      this.result = result;
      this.sandbox = sandbox;
      Port = this.sandbox.BiwaScheme.Port;
      Port.current_input = new Port.CustomInput(input);
      Port.current_output = new Port.CustomOutput(output);
      Port.current_error = Port.current_output;
      this.interpreter = new this.sandbox.BiwaScheme.Interpreter(error);
      ready();
    }
    Scheme.prototype.Eval = function(command) {
      try {
        return this.interpreter.evaluate(command, __bind(function(new_state) {
          var result;
          result = '';
          if ((new_state != null) && new_state !== this.sandbox.BiwaScheme.undef) {
            result = this.sandbox.BiwaScheme.to_write(new_state);
          }
          return this.result(result);
        }, this));
      } catch (e) {
        return this.interpreter.on_error(e.message);
      }
    };
    Scheme.prototype.IsCommandComplete = function(command) {
      var brackets, parens, token, tokens, _i, _len;
      tokens = new this.sandbox.BiwaScheme.Parser(command).tokens;
      parens = 0;
      brackets = 0;
      for (_i = 0, _len = tokens.length; _i < _len; _i++) {
        token = tokens[_i];
        switch (token) {
          case '[':
            ++brackets;
            break;
          case ']':
            --brackets;
            break;
          case '(':
            ++parens;
            break;
          case ')':
            --parens;
        }
      }
      return parens <= 0 && brackets <= 0;
    };
    Scheme.prototype.GetNextLineIndent = function(command) {
      var countParens, parens_in_last_line;
      countParens = __bind(function(str) {
        var parens, token, tokens, _i, _len;
        tokens = new this.sandbox.BiwaScheme.Parser(str).tokens;
        parens = 0;
        for (_i = 0, _len = tokens.length; _i < _len; _i++) {
          token = tokens[_i];
          switch (token) {
            case '[':
            case '(':
              ++parens;
              break;
            case ']':
            case ')':
              --parens;
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
    return Scheme;
  })();
}).call(this);
