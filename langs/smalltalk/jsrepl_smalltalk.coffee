class @JSREPL::Engines::Smalltalk
  constructor: (@input, @output, @result, @error, @sandbox, ready) ->
    @smalltalk = @sandbox.smalltalk
    ready()
  
  Parse: (command) ->
    compiler = @smalltalk.Compiler._new()
    return compiler._parseExpression_ command
    
  Eval: (command) ->
    node = @Parse command
    compiler = @smalltalk.Compiler._new()
    if node._isParseFailure()
      message = node._reason() + ', position: ' + node._position()
      @error message
    else
      @result compiler._loadExpression_ command
  
  GetNextLineIndent: (command) ->
    node = @Parse command
    return if node._isParseFailure() then 0 else false
      
    
