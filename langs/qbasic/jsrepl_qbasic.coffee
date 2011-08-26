# TODO(max99x): Implement standard library functions:
#   http://www.jgsee.kmutt.ac.th/exell/PracMath/IntrodQB.htm
#   http://www.qbasicstation.com/index.php?c=t_adv

class @JSREPL::Engines::QBasic
  constructor: (input, output, result, error, @sandbox, ready) ->
    # An interface to the QBasic VM.
    @virtual_machine = new @sandbox.QBasic.VirtualMachine {
      print: output
      input: input
      result: result
      error: error
    }
    ready()

  Eval: (command) ->
    try
      @virtual_machine.run command, =>
        if @virtual_machine.stack.length
          @virtual_machine.cons.result @virtual_machine.stack.pop().toString()
        else
          @virtual_machine.cons.result ''
    catch e
      @virtual_machine.cons.error e.message

  GetNextLineIndent: (command) ->
    @sandbox.QBasic.Program::createParser()
    parser = @sandbox.QBasic.Program.parser

    # If the command is parseable, we're done.
    if parser.parse(command + '\n') is not null then return false

    # If any open block is unclosed, the command is not complete. If any block
    # is closed with an invalid ending (e.g. an IF with a WEND), the command
    # contains an error and is considered complete.
    tokenizer = parser.tokenizer
    lines = (i + '\n' for i in command.split '\n')

    countBlocks = (lines, partial = false) ->
      open_blocks = []
      for line in lines
        if parser.parse line then continue

        tokenizer.setText line
        token = tokenizer.nextToken 0, 0
        first_token = token.text
        token = tokenizer.nextToken 0, token.locus.position + token.text.length
        second_token = token.text

        top_block = open_blocks[open_blocks.length - 1]

        switch first_token
          when 'SUB', 'FUNCTION', 'FOR', 'IF', 'SELECT', 'WHILE'
            open_blocks.push first_token
          when 'DO'
            open_blocks.push if second_token is 'WHILE' then 'DOWHILE' else 'DO'
          when 'ELSE'
            if partial and open_blocks.length == 0
              open_blocks.push 'IF'
            else if top_block isnt 'IF'
              return -1
          when 'WEND'
            if top_block is 'WHILE' then open_blocks.pop() else return -1
          when 'FOR'
            if top_block is 'NEXT' then open_blocks.pop() else return -1
          when 'LOOP'
            if second_token in ['WHILE', 'UNTIL']
              if top_block is 'DO' then open_blocks.pop() else return -1
            else
              if top_block is 'DOWHILE' then open_blocks.pop() else return -1
          when 'END'
            if top_block == second_token then open_blocks.pop() else return -1

      return open_blocks.length

    if countBlocks(lines) <= 0
      # All blocks closed or mismatch; don't continue.
      return false
    else
      # Check if a new block has just been opened.
      return if countBlocks([lines[-1..][0]], true) > 0 then 1 else 0
