class @JSREPL::Engines::Bloop
  constructor: (@input, @output, @result, @error, @sandbox, ready) ->
    @sandbox.BFloop.init @output
    ready()
  
  Eval: (command) ->
    try
      code = @sandbox.BFloop.compile command
      @result @sandbox.eval code
    catch e
      @error e
    
  GetNextLineIndent: (command) ->
    rOpen = /BLOCK\s+(\d+)\s*:\s*BEGIN/ig
    rClose = /BLOCK\s+(\d+)\s*:\s*END/ig
    
    match = (code) ->
      opens = code.match(rOpen) || []
      closes = code.match(rClose) || []
      return opens.length - closes.length
        
    
    if match(command) <= 0
      return false
    else 
      count = match command.split('\n')[-1..][0]
      if count > 0
        # Open block; indent.
        return 1
      else 
        return 0
