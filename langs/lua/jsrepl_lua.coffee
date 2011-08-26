class @JSREPL::Engines::Lua
  constructor: (unused_input, output, @result, @error, sandbox, ready) ->
    sandbox.print = (->)
    @error_buffer = []
    @Lua = sandbox.Module.Lua
    @Lua.initialize(null,
                    (chr) -> output String.fromCharCode chr
                    (chr) => @error_buffer.push String.fromCharCode chr)
    ready()

  Eval: (command) ->
    @error_buffer = []
    try
      result = @Lua.eval command
      if @error_buffer.length
        @error @error_buffer.join ''
      else
        @result result
    catch e
      @error e

  GetNextLineIndent: (command) ->
    return if @Lua.isFinished command then false else 0 
