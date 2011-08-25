$ = jQuery
jqconsole = null
jsrepl = null

# Defines global jQuery templates used by the various functions interacting
# with the UI.
DefineTemplates = ->
  $.template 'optgroup', '''
                         {{each(cat, names_arr) data}}
                           <optgroup label="${cat}">
                             {{each names_arr}}
                               <option value="${$value.value}">
                                 ${$value.display}
                               </option>
                             {{/each}}
                           </optgroup>
                         {{/each}}
                         '''
  $.template 'option', '<option>${value}</option>'

# Initializes the behaviour of the command prompt and the expand and eval
# buttons.
SetupConsole = (header='') ->
  jqconsole = $('#console').jqconsole header

# Shows a command prompt in the console and waits for input.
StartPrompt = ->
  Evaluate = (command)->
    $('#examples').val ''
    if command
      jsrepl.Evaluate command
    else
      StartPrompt()
  jqconsole.Prompt true, Evaluate, $.proxy(jsrepl.CheckLineEnd, jsrepl)

# Populates the languages dropdown from JSREPL::Languages and triggers the
# loading of the default language.
LoadLanguageDropdown= ->
  # Sort languages into categories.
  categories = {}
  for system_name, lang_def of JSREPL::Languages::
    if not categories[lang_def.category]?
      categories[lang_def.category] = []
    categories[lang_def.category].push
      display: lang_def.name
      value: system_name

  # Fill the dropdown.
  $languages = $('#languages')
  $languages.empty().append $.tmpl 'optgroup', data: categories

  # Link dropbox to language loading.
  $languages.change =>
    
    # TODO(amasad): Create a loading effect.
    $('body').toggleClass 'loading'
    lang = $languages.val()
    # Load logo.
    $('#lang_logo').attr 'src', lang.logo
    current_lang = JSREPL::Languages::[lang]
    # Register charecter matchings in jqconsole for the current language
    i = 0
    for [open, close] in current_lang.matchings
      jqconsole.RegisterMatching open, close, 'matching-' + (++i)
    
    # Load examples.  
    $.get current_lang.example_file, (raw_examples) =>
      # Clear the existing examples.
      examples = {}
      $examples = $('#examples')
      $examples.unbind 'change'
      $(':not(:first)', $examples).remove()

      # Parse out the new examples.
      example_parts = raw_examples.split /\*{80}/
      title = null
      for part in example_parts
        part = part.replace /^\s+|\s*$/g, ''
        if not part then continue
        if title
          code = part
          examples[title] = code
          title = null
        else
          title = part
          $examples.append $.tmpl 'option', value: title
      # Set up response to example selection.
      $examples.change =>
        code = examples[$examples.val()]
        jqconsole.SetPromptText code
        jqconsole.Focus()

    # Empty out the history, prompt and example selection.
    jqconsole.Reset()
    jqconsole.RegisterShortcut 'Z', =>
      jqconsole.AbortPrompt()
      StartPrompt()
    $('#examples').val ''
    jsrepl.LoadLanguage lang, =>
      $('body').toggleClass 'loading'
      StartPrompt()
      window.location.hash = lang.toLowerCase()

  # Load the default language by manually triggering change.
  $languages.change()

# Sets up the HashChange event handler. Handles cases were user is not
# entering language in correct case.
SetupURLHashChange = ->
  proper_case_langs = {}
  $.each Object.keys(JSREPL::Languages::), (i, lang) ->
    proper_case_langs[lang.toLowerCase()] = lang;

  $languages = $('#languages')

  $.hashchange (lang) ->
    lang = proper_case_langs[lang.toLowerCase()]
    if ($languages.find "[value=#{lang}]").length
      $languages.val lang
      $languages.change()

$ ->
  config = 
    # Receives the result of a command evaluation.
    #   @arg result: The user-readable string form of the result of an evaluation.
    ResultCallback: (result) ->
      if result
        jqconsole.Write '==> ' + result, 'result'
      StartPrompt()
    
    # Receives an error message resulting from a command evaluation.
    #   @arg error: A message describing the error.
    ErrorCallback: (error) ->
      jqconsole.Write String(error), 'error'
      StartPrompt()
      
    # Receives any output from a language engine. Acts as a low-level output
    # stream or port.
    #   @arg output: The string to output. May contain control characters.
    #   @arg cls: An optional class for styling the output.
    OutputCallback: (output, cls) ->
      jqconsole.Write output, cls
      return undefined
      
    # Receives a request for a string input from a language engine. Passes back
    # the user's response asynchronously.
    #   @arg callback: The function called with the string containing the user's
    #     response. Currently called synchronously, but that is *NOT* guaranteed.
    InputCallback: (callback) ->
      jqconsole.Input (result) =>
        try
          callback result
        catch e
          @ErrorCallback e
      return undefined
    
  jsrepl = new JSREPL config
  SetupConsole()
  DefineTemplates()
  LoadLanguageDropdown()
  
    
  
      
  