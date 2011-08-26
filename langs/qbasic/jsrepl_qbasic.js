(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.QBasic = (function() {
    function QBasic(input, output, result, error, sandbox, ready) {
      this.sandbox = sandbox;
      this.virtual_machine = new this.sandbox.QBasic.VirtualMachine({
        print: output,
        input: input,
        result: result,
        error: error
      });
      ready();
    }
    QBasic.prototype.Eval = function(command) {
      try {
        return this.virtual_machine.run(command, __bind(function() {
          if (this.virtual_machine.stack.length) {
            return this.virtual_machine.cons.result(this.virtual_machine.stack.pop().toString());
          } else {
            return this.virtual_machine.cons.result('');
          }
        }, this));
      } catch (e) {
        return this.virtual_machine.cons.error(e.message);
      }
    };
    QBasic.prototype.GetNextLineIndent = function(command) {
      var countBlocks, i, lines, parser, tokenizer;
      this.sandbox.QBasic.Program.prototype.createParser();
      parser = this.sandbox.QBasic.Program.parser;
      if (parser.parse(command + '\n') === !null) {
        return false;
      }
      tokenizer = parser.tokenizer;
      lines = (function() {
        var _i, _len, _ref, _results;
        _ref = command.split('\n');
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          _results.push(i + '\n');
        }
        return _results;
      })();
      countBlocks = function(lines, partial) {
        var first_token, line, open_blocks, second_token, token, top_block, _i, _len;
        if (partial == null) {
          partial = false;
        }
        open_blocks = [];
        for (_i = 0, _len = lines.length; _i < _len; _i++) {
          line = lines[_i];
          if (parser.parse(line)) {
            continue;
          }
          tokenizer.setText(line);
          token = tokenizer.nextToken(0, 0);
          first_token = token.text;
          token = tokenizer.nextToken(0, token.locus.position + token.text.length);
          second_token = token.text;
          top_block = open_blocks[open_blocks.length - 1];
          switch (first_token) {
            case 'SUB':
            case 'FUNCTION':
            case 'FOR':
            case 'IF':
            case 'SELECT':
            case 'WHILE':
              open_blocks.push(first_token);
              break;
            case 'DO':
              open_blocks.push(second_token === 'WHILE' ? 'DOWHILE' : 'DO');
              break;
            case 'ELSE':
              if (partial && open_blocks.length === 0) {
                open_blocks.push('IF');
              } else if (top_block !== 'IF') {
                return -1;
              }
              break;
            case 'WEND':
              if (top_block === 'WHILE') {
                open_blocks.pop();
              } else {
                return -1;
              }
              break;
            case 'FOR':
              if (top_block === 'NEXT') {
                open_blocks.pop();
              } else {
                return -1;
              }
              break;
            case 'LOOP':
              if (second_token === 'WHILE' || second_token === 'UNTIL') {
                if (top_block === 'DO') {
                  open_blocks.pop();
                } else {
                  return -1;
                }
              } else {
                if (top_block === 'DOWHILE') {
                  open_blocks.pop();
                } else {
                  return -1;
                }
              }
              break;
            case 'END':
              if (top_block === second_token) {
                open_blocks.pop();
              } else {
                return -1;
              }
          }
        }
        return open_blocks.length;
      };
      if (countBlocks(lines) <= 0) {
        return false;
      } else {
        if (countBlocks([lines.slice(-1)[0]], true) > 0) {
          return 1;
        } else {
          return 0;
        }
      }
    };
    return QBasic;
  })();
}).call(this);
