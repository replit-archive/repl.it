(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.LOLCODE = (function() {
    function LOLCODE(input, output, result, error, sandbox, ready) {
      var error_handler, input_handler, output_handler, result_handler;
      this.error = error;
      this.sandbox = sandbox;
      input_handler = __bind(function() {
        return input(__bind(function(text) {
          return this.machine.resume(text);
        }, this));
      }, this);
      output_handler = __bind(function(text) {
        output(text);
        return this.machine.resume();
      }, this);
      error_handler = __bind(function(e) {
        error(e);
        this.machine.reset();
        this.machine.halted = true;
        return this.machine.instruction_ptr = this.machine.instructions.length;
      }, this);
      result_handler = __bind(function() {
        var it;
        it = this.machine.frames[0].variables['IT'];
        if (it === this.last_it) {
          return result('');
        } else {
          this.last_it = it;
          return result(it.value === null ? '' : String(it.value));
        }
      }, this);
      this.context = new this.sandbox.LOLCoffee.CodeGenContext;
      this.machine = new this.sandbox.LOLCoffee.Machine(this.context, input_handler, output_handler, error_handler, result_handler, true);
      this.last_it = null;
      ready();
    }
    LOLCODE.prototype.Eval = function(command) {
      var parsed, tokenized;
      try {
        tokenized = new this.sandbox.LOLCoffee.Tokenizer(command).tokenize();
        parsed = new this.sandbox.LOLCoffee.Parser(tokenized).parseProgram();
        parsed.codegen(this.context);
      } catch (e) {
        this.error(e);
        return;
      }
      return this.machine.run();
    };
    LOLCODE.prototype.GetNextLineIndent = function(command) {
      var countBlocks, current_line, lines, parsed, token, tokenized, _i, _len;
      if (/\.\.\.\s*$/.test(command)) {
        return 0;
      }
      try {
        tokenized = new this.sandbox.LOLCoffee.Tokenizer(command).tokenize();
      } catch (e) {
        return false;
      }
      try {
        parsed = new this.sandbox.LOLCoffee.Parser(tokenized.slice(0)).parseProgram();
        return false;
      } catch (e) {
        lines = [];
        current_line = [];
        for (_i = 0, _len = tokenized.length; _i < _len; _i++) {
          token = tokenized[_i];
          if (token.type === 'endline') {
            lines.push(current_line);
            current_line = [];
          } else {
            current_line.push(token);
          }
        }
        countBlocks = function(lines, partial) {
          var line, open_blocks, top_block, _j, _len2;
          if (partial == null) {
            partial = false;
          }
          open_blocks = [];
          for (_j = 0, _len2 = lines.length; _j < _len2; _j++) {
            line = lines[_j];
            top_block = open_blocks[open_blocks.length - 1];
            switch (line[0].text) {
              case 'HAI':
                open_blocks.push('KTHXBYE');
                break;
              case 'HOW DUZ I':
                open_blocks.push('IF U SAY SO');
                break;
              case 'IM IN YR':
                open_blocks.push('IM OUTTA YR');
                break;
              case 'O RLY?':
              case 'WTF?':
                open_blocks.push('OIC');
                break;
              case 'YA RLY':
              case 'NO WAI':
              case 'MEBBE':
                if (partial && open_blocks.length === 0) {
                  open_blocks.push('OIC');
                } else if (open_blocks[open_blocks.length - 1] !== 'OIC') {
                  return -1;
                }
                break;
              case 'KTHXBYE':
              case 'IF U SAY SO':
              case 'IM OUTTA YR':
              case 'OIC':
                if (open_blocks[open_blocks.length - 1] === line[0].text) {
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
      }
    };
    return LOLCODE;
  })();
}).call(this);
