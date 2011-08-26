isNil = (x) ->
  (not x?) or (x instanceof Array and x.length == 0)

class @JSREPL::Engines::Lisp
  constructor: (input, output, result, @error, @sandbox, ready, libs) ->
    Javathcript = @Javathcript = @sandbox.Javathcript
    Javathcript.Environment::princ = (obj, callback) ->
      this._value obj, (val) ->
        output Javathcript.environment._stringify val
        callback val

    Javathcript.Environment::print = (obj, callback) ->
      this._value obj, (val) ->
        output Javathcript.environment._stringify val
        output '\n'
        callback val

    Javathcript.Environment::input = (callback) ->
      input (str) ->
        callback new Javathcript.Atom str

    Javathcript.Environment::_error = error

    for f in ['princ', 'print', 'input', '_error']
      Javathcript.Environment::[f].toString = -> '{library macro}'

    @result_handler = (r) ->
      result if isNil(r) then '' else r.toString()

    i = 0
    do load = ()->
      if lib = libs[i++]
        Javathcript.evalMulti lib, (->), load
      else
        do ready
      

  Eval: (command) ->
    try
      @Javathcript.eval command, @result_handler
    catch e
      try
        last_result = null
        handleMultiResult = (r) => last_result = r
        @Javathcript.evalMulti command, handleMultiResult, =>
          @result_handler last_result
      catch e
        @error e.message

  GetNextLineIndent: (command) ->
    countParens = (str) =>
      tokenizer = new @Javathcript.Tokenizer str
      assembly = new @Javathcript.BPWJs.TokenAssembly tokenizer
      tokens = assembly.tokenString.tokens
      parens = 0

      for token in tokens
        if token.ttype is 'symbol'
          switch token.sval
            when '(' then ++parens
            when ')' then --parens

      return parens

    if countParens(command) <= 0
      # All S-exps closed or extra closing parens; don't continue.
      return false
    else
      parens_in_last_line = countParens command.split('\n')[-1..][0]
      if parens_in_last_line > 0
        # A new S-exp opened on the last line; indent one level.
        return 1
      else if parens_in_last_line < 0
        # Some S-exps were closed; realign with the outermost closed S-exp.
        return parens_in_last_line
      else
        return 0
