class @JSREPL::Engines::Brainfuck
  constructor: (input, output, @result, @error, @sandbox, ready) ->
    @result_handler = (data, index) =>
      epi = '...'
      # Copy the data array
      cells = data.map (x) -> x
      # When we are at a newly visited unmodified cell 
      # the data array length is wrong.
      cells.length = if cells.length < index then index + 1 else cells.length
      cells[i] ||= 0 for v,i in cells
      
      if index < 10
         lower = 0 
      else 
         lower = index - 10
         cells[lower] = epi + cells[lower]
      
      cells[index] ||= 0
      before = cells[lower...index]
      if cells[index + 10]? then cells[index + 10] += epi
      after = cells[index + 1..index + 10]
      @result before.concat([ '[' + cells[index] + ']' ]).concat(after).join ' '
      
    # TODO(amasad): Buffer input.
    @BFI = new @sandbox.BF.Interpreter input, output, @result_handler
      
    ready()

  Eval: (command) ->
    try
      if command == "SHOWTAPE"
        # to be implemented
        @BFI.result = (data,index) =>
          cells = data.map (x) -> x
          cells.length = if cells.length < index then index + 1 else cells.length
          cells[i] ||= 0 for v,i in cells
          cells[index] ||= 0
          cells[index] = '[' + cells[index] + ']'
          @result cells.join ' '
          
        @BFI.evaluate ''
        @BFI.result = @result_handler
      else if command == "RESET"
        @BFI.reset()
        @result ''
      else
        @BFI.evaluate(command)
        
    catch e
      @error e

  GetNextLineIndent: (command) ->
    countParens = (str) =>
      tokens = str.split ''
      parens = 0

      for token in tokens
          switch token
            when '[' then ++parens
            when ']' then --parens

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
