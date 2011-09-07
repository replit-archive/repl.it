# Holds the core application logic and all interactions with JSREPL.
# Emits events so other modules can hook into.

# Core module

$ = jQuery

$.extend REPLIT,
  Init: ->
    @jsrepl = new JSREPL {
      InputCallback: $.proxy @InputCallback, @
      OutputCallback: $.proxy @OutputCallback, @
      ResultCallback: $.proxy @ResultCallback, @
      ErrorCallback: $.proxy @ErrorCallback, @
    }
    # Init console.
    @jqconsole = @$consoleContainer.jqconsole '', '   ', '.. '
    @$console = @$consoleContainer.find '.jqconsole'

    # Init editor.
    @editor = ace.edit 'editor-widget'
    @editor.setTheme 'ace/theme/textmate'
    @editor.renderer.setHScrollBarAlwaysVisible false
    @$editor = @$editorContainer.find '#editor-widget'
    @$run.click =>
      @jqconsole.AbortPrompt()
      @Evaluate REPLIT.editor.getSession().getValue()

    @current_lang = null
    @inited = true

  # Load a given language by name.
  LoadLanguage: (lang_name, callback=$.noop) ->
    @$this.trigger 'language_loading', [lang_name]
    @current_lang = JSREPL::Languages::[lang_name]
    # Hold the name for saving and such.
    @current_lang.system_name = lang_name

    #Load Ace mode.
    EditSession = require("ace/edit_session").EditSession
    session = new EditSession ''
    ace_mode = @Languages[lang_name].ace_mode
    if ace_mode?
      $.getScript ace_mode.script, =>
        mode = require(ace_mode.module).Mode
        session.setMode new mode
        @editor.setSession session
    else
      textMode = require("ace/mode/text").Mode
      session.setMode new textMode
      @editor.setSession session

    # Empty out the history and prompt.
    @jqconsole.Reset()
    # Register character matchings in jqconsole for the current language.
    for [open, close], index in @current_lang.matchings
      @jqconsole.RegisterMatching open, close, 'matching-' + index

    @jqconsole.RegisterShortcut 'Z', =>
      @jqconsole.AbortPrompt()
      @StartPrompt()
    @jsrepl.LoadLanguage lang_name, =>
      @StartPrompt()
      @$this.trigger 'language_loaded', [lang_name]
      callback()
      

  # Receives the result of a command evaluation.
  #   @arg result: The user-readable string form of the result of an evaluation.
  ResultCallback: (result) ->
    if result
      @jqconsole.Write '=> ' + result, 'result'
    @StartPrompt()
    @$this.trigger 'result', [result]
  # Receives an error message resulting from a command evaluation.
  #   @arg error: A message describing the error.
  ErrorCallback: (error) ->
    if typeof error == 'object'
      error = error.message
    @jqconsole.Write String(error), 'error'
    @StartPrompt()
    @$this.trigger 'error', [error]
  # Receives any output from a language engine. Acts as a low-level output
  # stream or port.
  #   @arg output: The string to output. May contain control characters.
  #   @arg cls: An optional class for styling the output.
  OutputCallback: (output, cls) ->
    @jqconsole.Write output, cls
    @$this.trigger 'output', [output]
    return undefined
  # Receives a request for a string input from a language engine. Passes back
  # the user's response asynchronously.
  #   @arg callback: The function called with the string containing the user's
  #     response. Currently called synchronously, but that is *NOT* guaranteed.
  InputCallback: (callback) ->
    @jqconsole.Input (result) =>
      try
        callback result
        #Should it be here?
        @$this.trigger 'input', [result]
      catch e
        @ErrorCallback e
    return undefined

  Evaluate: (command) ->
    if command
      @jsrepl.Evaluate command
      @$this.trigger 'eval', [command]
    else
      @StartPrompt()
  # Shows a command prompt in the console and waits for input.
  StartPrompt: ->
    @jqconsole.Prompt true, $.proxy(@Evaluate, @), $.proxy(@jsrepl.CheckLineEnd, @jsrepl)

$ ->
  REPLIT.Init()
  REPLIT.OnResize()
  # Shitty sucky new chrome
  setTimeout (-> REPLIT.OnResize()), 500

