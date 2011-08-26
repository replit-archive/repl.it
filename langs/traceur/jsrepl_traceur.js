(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.JSREPL.prototype.Engines.prototype.Traceur = (function() {
    function Traceur(input, output, result, error, sandbox, ready) {
      this.result = result;
      this.error = error;
      this.sandbox = sandbox;
      this.inspect = this.sandbox._inspect;
      this.sandbox.__eval = this.sandbox.eval;
      this.traceur = this.sandbox.traceur;
      this.sandbox.console.log = __bind(function(obj) {
        return output(obj + '\n');
      }, this);
      this.sandbox.console.dir = __bind(function(obj) {
        return output(this.inspect(obj) + '\n');
      }, this);
      this.sandbox.console.read = input;
      ready();
    }
    Traceur.prototype.Eval = function(command) {
      var source;
      try {
        source = this._Compile(command);
      } catch (e) {
        this.error(e);
        return;
      }
      try {
        return this.result(this.inspect(this.sandbox.__eval(source)));
      } catch (e) {
        return this.error(e);
      }
    };
    Traceur.prototype.GetNextLineIndent = function(command) {
      var last_line;
      try {
        this._Compile(command);
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
    Traceur.prototype._Compile = function(command) {
      var errors, project, reporter, res;
      errors = [];
      reporter = new this.traceur.util.ErrorReporter;
      reporter.reportMessageInternal = function(location, kind, format, args) {
        var i, message;
        i = 0;
        message = format.replace(/%s/g, function() {
          return args[i++];
        });
        return errors.push(location ? "" + location + ": " + message : message);
      };
      project = new this.traceur.semantics.symbols.Project;
      project.addFile(new this.traceur.syntax.SourceFile('REPL', command));
      res = this.traceur.codegeneration.Compiler.compile(reporter, project, false);
      if (reporter.hadError()) {
        throw new Error(errors.join('\n'));
      } else {
        return this.traceur.codegeneration.ProjectWriter.write(res);
      }
    };
    return Traceur;
  })();
}).call(this);
