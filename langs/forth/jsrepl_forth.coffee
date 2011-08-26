# How many stack items to print when showing the result of a command.
RESULT_SIZE = 5

class @JSREPL::Engines::Forth
  constructor: (input, output, result, error, @sandbox, ready) ->
    # Have we printed at least one character this run?
    @printed = false
    # Have we already called the result or error callback?
    @finished = false
    # Are we currently reading data?
    @inputting = false
    # How many lines does the current command contain?
    @lines = 0

    # Initialize the VM.
    @sandbox._init()

    # Customize callbacks.
    @sandbox._error = (e) =>
      @finished = true
      error e
    @sandbox._print = (str) =>
      @printed = true
      output str
    @sandbox._prompt = =>
      if --@lines == 0 and not @inputting and not @finished
        @sandbox._finish()
    @sandbox._input = (callback) =>
      if @finished then return
      @inputting = true
      input (result) =>
        for chr in result
          @sandbox.inbuf.push chr.charCodeAt 0
        @sandbox.inbuf.push 13
        @inputting = false
        callback()
    @sandbox._finish = =>
      if @finished then return
      @sandbox.inbuf = []
      top = @sandbox._stacktop RESULT_SIZE + 1
      if top.length
        if top.length > RESULT_SIZE then top[0] = '...'
        result top.join ' '
      else
        if @printed then output '\n'
        result ''
      @finished = true

    ready()

  Eval: (command) ->
    @printed = false
    @finished = false
    @inputting = false
    @lines = command.split('\n').length

    try
      @sandbox._run command
    catch e
      @sandbox._error e
      return

  GetNextLineIndent: (command) ->
    countParens = (str) =>
      depth = 0

      for token in str.split /\s+/
        switch token
          when ':' then ++depth
          when ';' then --depth

      return depth

    if countParens(command) <= 0
      # All functions closed or extra closing semicolons; don't continue.
      return false
    else
      parens_in_last_line = countParens command.split('\n')[-1..][0]
      if parens_in_last_line > 0
        # A new function opened on the last line; indent one level.
        return 1
      else if parens_in_last_line < 0
        # Some functions were closed; realign with the outermost closed one.
        return parens_in_last_line
      else
        return 0
