class @JSREPL::Engines::JavaScript
  constructor: (input, output, @result, @error, @sandbox, ready) ->
    # Cache sandboxed objects and functions used by the engine in case sandbox
    # bindings hide them.
    @inspect = @sandbox._inspect
    @functionClass = @sandbox.Function
    @sandbox.__eval = @sandbox.eval

    # Define custom I/O handlers.
    @sandbox.console.log = (obj) => output obj + '\n'
    @sandbox.console.dir = (obj) => output @inspect(obj) + '\n'
    @sandbox.console.read = input

    ready()

  Eval: (command) ->
    try
      result = @sandbox.__eval command
      @result @inspect result
    catch e
      @error e

  GetNextLineIndent: (command) ->
    try
      new @functionClass command
      return false
    catch e
      if /[\[\{\(]$/.test command
        # An opening brace, bracket or paren; indent.
        return 1
      else
        return 0
