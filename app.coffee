$ = jQuery
TEMPLATES =
  category: '''
    <h3>{{name}}</h3>
    <ul>
      {{#languages}}
        <li><a data-langname="{{name}}">{{{formatted}}}</a></li>
      {{/languages}}
    </ul>
  '''
  languageMenu: '''
    <h2>Please Select Your Language</h2>
    <div class="cat-list">
      {{#categories}}
        <div class="category">
          {{>category}}
        </div>
      {{/categories}}
    </div>
  '''
  examples: '''
    <ul>
    {{#examples}}
      <li><a href="#" data-index={{index}}>{{title}}</a></li>
    {{/examples}}
    </ul>
  '''
LANG_CATEGORIES =
  Classic: ['QBasic', 'Forth', 'Smalltalk']
  Esoteric: ['LOLCODE', 'Brainfuck', 'Emoticon', 'Bloop', 'Unlambda']
  Web: ['JavaScript', 'Traceur', 'CoffeeScript', 'Kaffeine', 'Move']
  Practical: ['Scheme', 'Lua', 'Python']

REPLIT =
  # jQuery elems.
  $container: null
  $consoleContainer: null
  $editorContainer: null
  $console: null
  $editor: null
  $resizer: null
  
  Init: ->
    @jsrepl = new JSREPL {
      InputCallback: $.proxy @InputCallback, @
      OutputCallback: $.proxy @OutputCallback, @
      ResultCallback: $.proxy @ResultCallback, @
      ErrorCallback: $.proxy @ErrorCallback, @
    }
    @jqconsole = @$consoleContainer.jqconsole ''
    @$console = @$consoleContainer.find '.jqconsole'
    
    @editor = ace.edit 'editor'
    @editor.setTheme 'ace/theme/solarized_light'
    @$editor = @$editorContainer.find '#editor'
    
    @examples = []
    @current_lang = null

    # Render language selection templates.
    templateCategories = []
    for categoryName, languages of LANG_CATEGORIES
      templateLanguages = []
      for lang in languages
        name = @Languages[lang].name
        shortcutIndex = name.indexOf @Languages[lang].shortcut
        formattedShortcut = "<span>#{name.charAt(shortcutIndex)}</span>"
        formatted = name[...shortcutIndex] + formattedShortcut + name[shortcutIndex + 1...]
        templateLanguages.push {name, formatted}
      templateCategories.push {name: categoryName, languages: templateLanguages}
    lang_sel_html = Mustache.to_html TEMPLATES.languageMenu, {categories: templateCategories}, TEMPLATES
    $('#language-selector').append lang_sel_html
    @inited = true
    
  # Shows a command prompt in the console and waits for input.
  StartPrompt: ->
    Evaluate = (command) =>
      if command
        @jsrepl.Evaluate command
      else
        @StartPrompt()
    @jqconsole.Prompt true, Evaluate, $.proxy(@jsrepl.CheckLineEnd, @jsrepl)

  # Load a given language by name.
  LoadLanguage: (lang_name) ->
    $.nav.pushState "/#{lang_name.toLowerCase()}"

  # Sets up the HashChange event handler. Handles cases were user is not
  # entering language in correct case.
  SetupURLHashChange: ->
    langs = {}
    for lang_name, lang of @Languages
      langs[lang_name.toLowerCase()] = {lang_name, lang};
    jQuery.nav (lang_name, link) =>
      if langs[lang_name]?
        lang_name = langs[lang_name].lang_name
        # TODO(amasad): Create a loading effect.
        $('body').toggleClass 'loading'

        @current_lang = JSREPL::Languages::[lang_name]

        # Register charecter matchings in jqconsole for the current language
        i = 0
        for [open, close] in @current_lang.matchings
          @jqconsole.RegisterMatching open, close, 'matching-' + (++i)

        # Load examples.
        $.get @Languages[lang_name].example_file, (raw_examples) =>
          # Clear the existing examples.
          @examples = []
          # Parse out the new examples.
          example_parts = raw_examples.split /\*{80}/
          title = null
          for part in example_parts
            part = part.replace /^\s+|\s*$/g, ''
            if not part then continue
            if title
              code = part
              @examples.push {
                title
                code
                index: @examples.length
              }
              title = null
            else
              title = part

          # Render examples.
          examples_sel_html = Mustache.to_html TEMPLATES.examples, {examples: @examples}
          $('#examples-selector').empty().append examples_sel_html
          # Set up response to example selection.

        # Empty out the history, prompt and example selection.
        @jqconsole.Reset()
        @jqconsole.RegisterShortcut 'Z', =>
          @jqconsole.AbortPrompt()
          @StartPrompt()
        @jsrepl.LoadLanguage lang_name, =>
          $('body').toggleClass 'loading'
          @StartPrompt()

  # Langauge selection overlay method.
  ShowLanguagesOverlay: ->
    $doc = $(document)
    selected = false
    jQuery.facebox {div: '#language-selector'}, 'languages'
    $('#facebox .content.languages .cat-list span').each (i, elem) =>
      $elem = $(elem)
      $doc.bind 'keyup.languages', (e) =>
        upperCaseCode = $elem.text().toUpperCase().charCodeAt(0)
        lowerCaseCode = $elem.text().toLowerCase().charCodeAt(0)
        if e.keyCode == upperCaseCode or e.keyCode == lowerCaseCode
          $doc.trigger 'close.facebox'
          selected = true
          @LoadLanguage $elem.parent().data 'langname'

    $doc.bind 'close.facebox.languages', =>
      $doc.unbind 'keyup.languages'
      $doc.unbind 'close.facebox.languages'
      @StartPrompt() if not selected

    @jqconsole.AbortPrompt() if @jqconsole.state == 2

  ShowExamplesOverlay: ->
    jQuery.facebox {div: '#examples-selector'}, 'examples'
    that = @
    $('#facebox .content.examples ul a').click (e) ->
      e.preventDefault()
      example = that.examples[$(this).data 'index']
      $(document).trigger 'close.facebox'
      that.jqconsole.SetPromptText example.code
      that.jqconsole.Focus()

  # Receives the result of a command evaluation.
  #   @arg result: The user-readable string form of the result of an evaluation.
  ResultCallback: (result) ->
    if result
      @jqconsole.Write '==> ' + result, 'result'
    @StartPrompt()
  # Receives an error message resulting from a command evaluation.
  #   @arg error: A message describing the error.
  ErrorCallback: (error) ->
    @jqconsole.Write String(error), 'error'
    @StartPrompt()
  # Receives any output from a language engine. Acts as a low-level output
  # stream or port.
  #   @arg output: The string to output. May contain control characters.
  #   @arg cls: An optional class for styling the output.
  OutputCallback: (output, cls) ->
    @jqconsole.Write output, cls
    return undefined
  # Receives a request for a string input from a language engine. Passes back
  # the user's response asynchronously.
  #   @arg callback: The function called with the string containing the user's
  #     response. Currently called synchronously, but that is *NOT* guaranteed.
  InputCallback: (callback) ->
    @jqconsole.Input (result) =>
      try
        callback result
      catch e
        @ErrorCallback e
    return undefined
  
  InitResizer: ->
    $('div').disableSelection()
    $body = $('body')
    mousemove = (e) =>
      left = e.pageX
      @$resizer.css 'left', left
    
    @$resizer.mousedown (e) =>
      $body.mousemove mousemove
      

    @$resizer.mouseup =>
      $body.unbind 'mousemove'
      console.log 'stop drag'
  
  # Resize containers on each window resize.
  OnResize: ->
    width = document.documentElement.clientWidth
    height = document.documentElement.clientHeight - 50
    @$resizer.css 'left', width / 2
    @$container.css 
      width: width
      height: height
    @$editorContainer.css
      width: width / 2
      height: height
    @$consoleContainer.css
      width: width / 2
      height: height
    # Call to resize environment if the app has already initialized.
    REPLIT.EnvResize() if @inited
    
  EnvResize: ->
    # Calculate real height.
    console_hpadding = @$console.innerWidth() - @$console.width()
    console_vpadding = @$console.innerHeight() - @$console.height()
    editor_hpadding = @$editor.innerWidth() - @$editor.width()
    # + 30 for the control menu above the editor.
    editor_vpadding = @$editor.innerHeight() - @$editor.height() + 30
    
    @$console.css 'width', @$consoleContainer.width() - console_hpadding
    @$console.css 'height', @$consoleContainer.height() - console_vpadding
    @$editor.css 'width', @$editorContainer.innerWidth() - editor_hpadding
    @$editor.css 'height', @$editorContainer.innerHeight() - editor_vpadding 
    @editor.resize()
    
$ ->
  REPLIT.$container = $('#content')
  REPLIT.$editorContainer = $('#editor-container')
  REPLIT.$consoleContainer = $('#console')
  REPLIT.$resizer = $('#resize')
  REPLIT.InitResizer()
  REPLIT.OnResize()
  $(window).bind 'resize', ()-> REPLIT.OnResize()
  
  JSREPLLoader.onload ->
    REPLIT.Init()
    REPLIT.EnvResize()
    $(window).load ->
      # Hack for chrome and FF 4 fires an additional popstate on window load.
      setTimeout (-> REPLIT.SetupURLHashChange()), 0
    $(document).keyup (e)->
      # Escape key
      if e.keyCode == 27 and not $('#facebox').is(':visible')
        REPLIT.ShowLanguagesOverlay()

    $('#examples-button').click (e) ->
      e.preventDefault()
      REPLIT.ShowExamplesOverlay()

    $('#languages-button').click (e) ->
      e.preventDefault()
      REPLIT.ShowLanguagesOverlay()

# Export globally.
@REPLIT = REPLIT

$.fn.disableSelection = () ->
  ###
    this.each ()->  
    console.log this       
        $(this).attr('unselectable', 'on')
               .css({
                   '-moz-user-select':'none',
                   '-webkit-user-select':'none',
                   'user-select':'none'
               })
               .each(function() {
                   this.onselectstart = function() { return false; };
               });
    });
};
  ###