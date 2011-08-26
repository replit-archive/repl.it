(function() {
  this.JSREPL.prototype.Engines.prototype.Smalltalk = (function() {
    function Smalltalk(input, output, result, error, sandbox, ready) {
      this.input = input;
      this.output = output;
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.smalltalk = this.sandbox.smalltalk;
      ready();
    }
    Smalltalk.prototype.Parse = function(command) {
      var compiler;
      compiler = this.smalltalk.Compiler._new();
      return compiler._parseExpression_(command);
    };
    Smalltalk.prototype.Eval = function(command) {
      var compiler, message, node;
      node = this.Parse(command);
      compiler = this.smalltalk.Compiler._new();
      if (node._isParseFailure()) {
        message = node._reason() + ', position: ' + node._position();
        return this.error(message);
      } else {
        return this.result(compiler._loadExpression_(command));
      }
    };
    Smalltalk.prototype.GetNextLineIndent = function(command) {
      var node;
      node = this.Parse(command);
      if (node._isParseFailure()) {
        return 0;
      } else {
        return false;
      }
    };
    return Smalltalk;
  })();
}).call(this);
