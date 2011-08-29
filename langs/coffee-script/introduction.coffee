Course 'CoffeeScript', 'Course Title', ->
  link 'http://jashkenas.github.com/coffee-script/'
  introduction '''
    CoffeeScript is the Shit!
  '''
  chapter 'Syntax', ->
    introduction '''
      The syntax is awesome, comments are like that, semicolons are blah!
    '''
    exercise 'functions', ->
      text '''
        In JavaScript functions play a very important role in the language.  
        Functions are considered first-class objects and is used extensivley in the language,
        therefor CoffeeScript got rid of the 11 charecter `function` keyword, and replaced it
        with a simple arrow `->`:
        
              foo = -> 'bar'
          
              function foo() {
                return 'bar'
              }
              
        You can define an optional list of parameters in paranthesis:
          
              identity = (x) -> x
      '''
      question ->
        prompt 'Write a function `square` that takes an number `x` and returns its square'
        callback (AST, _eval) ->
          _eval('typeof square == "function" and square(3) == 9 and square(4) == 16 and square(10) == 100') == true
        success 'Good Job'
        fail 'Try again'
        hint 'Yo momma is ugly'
      question ->
        prompt 'Enter blah'
        callback (AST, _eval) ->
          true
  
  chapter 'Classes', ->
    introduction '''
      Classes is a fucking must! At least thats what I heard!
    '''
    exercise 'Basics', ->
      text '''
        classes.. clases.. classes classes
      '''
      question ->
        prompt 'Write a class Animal that takes a name'
        callback (AST, _eval) ->
          _eval('Animal?') and _eval('new Animal(\'x\').name') == 'x'
          