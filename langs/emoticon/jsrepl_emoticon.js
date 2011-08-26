(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.Emoticon = (function() {
    function Emoticon(input, output, result, error, sandbox, ready) {
      this.input = input;
      this.output = output;
      this.error = error;
      this.sandbox = sandbox;
      this.result_handler = __bind(function(env) {
        var len, list, listName, listStr, result_env;
        result_env = '';
        for (listName in env) {
          list = env[listName];
          listStr = list.toString();
          len = listStr.length - 74;
          len = len > 0 ? len : 0;
          listStr = listStr.slice(len);
          if (len > 0) {
            listStr = '...' + listStr;
          }
          result_env += ("\n" + listName + ": ") + listStr;
        }
        return result(result_env);
      }, this);
      this.interpreter = new this.sandbox.Emoticon.Interpreter({
        source: [],
        input: this.input,
        print: this.output,
        result: this.result_handler
      });
      ready();
    }
    Emoticon.prototype.Eval = function(command) {
      var code;
      try {
        code = new this.sandbox.Emoticon.Parser(command);
        this.interpreter.lists.Z = this.interpreter.lists.Z.concat(code);
        return this.interpreter.run();
      } catch (e) {
        return this.error(e);
      }
    };
    Emoticon.prototype.GetNextLineIndent = function(command) {
      var countParens, parens_in_last_line;
      countParens = __bind(function(str) {
        var parens, token, tokens, _i, _len;
        tokens = new this.sandbox.Emoticon.Parser(str);
        parens = 0;
        for (_i = 0, _len = tokens.length; _i < _len; _i++) {
          token = tokens[_i];
          if (token.mouth) {
            switch (token.mouth) {
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
    return Emoticon;
  })();
}).call(this);
