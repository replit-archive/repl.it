(function() {
  var RESULT_SIZE;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  RESULT_SIZE = 5;
  this.JSREPL.prototype.Engines.prototype.Forth = (function() {
    function Forth(input, output, result, error, sandbox, ready) {
      this.sandbox = sandbox;
      this.printed = false;
      this.finished = false;
      this.inputting = false;
      this.lines = 0;
      this.sandbox._init();
      this.sandbox._error = __bind(function(e) {
        this.finished = true;
        return error(e);
      }, this);
      this.sandbox._print = __bind(function(str) {
        this.printed = true;
        return output(str);
      }, this);
      this.sandbox._prompt = __bind(function() {
        if (--this.lines === 0 && !this.inputting && !this.finished) {
          return this.sandbox._finish();
        }
      }, this);
      this.sandbox._input = __bind(function(callback) {
        if (this.finished) {
          return;
        }
        this.inputting = true;
        return input(__bind(function(result) {
          var chr, _i, _len;
          for (_i = 0, _len = result.length; _i < _len; _i++) {
            chr = result[_i];
            this.sandbox.inbuf.push(chr.charCodeAt(0));
          }
          this.sandbox.inbuf.push(13);
          this.inputting = false;
          return callback();
        }, this));
      }, this);
      this.sandbox._finish = __bind(function() {
        var top;
        if (this.finished) {
          return;
        }
        this.sandbox.inbuf = [];
        top = this.sandbox._stacktop(RESULT_SIZE + 1);
        if (top.length) {
          if (top.length > RESULT_SIZE) {
            top[0] = '...';
          }
          result(top.join(' '));
        } else {
          if (this.printed) {
            output('\n');
          }
          result('');
        }
        return this.finished = true;
      }, this);
      ready();
    }
    Forth.prototype.Eval = function(command) {
      this.printed = false;
      this.finished = false;
      this.inputting = false;
      this.lines = command.split('\n').length;
      try {
        return this.sandbox._run(command);
      } catch (e) {
        this.sandbox._error(e);
      }
    };
    Forth.prototype.GetNextLineIndent = function(command) {
      var countParens, parens_in_last_line;
      countParens = __bind(function(str) {
        var depth, token, _i, _len, _ref;
        depth = 0;
        _ref = str.split(/\s+/);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          token = _ref[_i];
          switch (token) {
            case ':':
              ++depth;
              break;
            case ';':
              --depth;
          }
        }
        return depth;
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
    return Forth;
  })();
}).call(this);
