class @JSREPL::Engines::Emoticon
  constructor: (@input, @output, result, @error, @sandbox, ready) ->
    
    @result_handler = (env) =>
      result_env = ''
      for listName, list of env
        listStr = list.toString()
        len = listStr.length - 74
        len = if len > 0 then len else 0
        listStr = listStr[len...]
        listStr = '...' + listStr if len > 0
        result_env += "\n#{listName}: " + listStr
      result result_env
      
    @interpreter = new @sandbox.Emoticon.Interpreter {
      source: []
      input: @input
      print: @output
      result: @result_handler
    } 
    ready()
  
  Eval: (command) ->
    try
      code = new @sandbox.Emoticon.Parser command
      @interpreter.lists.Z = @interpreter.lists.Z.concat(code)
      @interpreter.run()
    catch e
      @error e
  
  GetNextLineIndent: (command) ->
    countParens = (str) =>
      tokens = new @sandbox.Emoticon.Parser str
      parens = 0

      for token in tokens
        if token.mouth
          switch token.mouth
            when '(' then ++parens
            when ')' then --parens

      return parens

    if countParens(command) <= 0
      return false
    else
      parens_in_last_line = countParens command.split('\n')[-1..][0]
      if parens_in_last_line > 0
        return 1
      else if parens_in_last_line < 0
        return parens_in_last_line
      else
        return 0
          
        
         
    