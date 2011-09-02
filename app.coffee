CONTENT_PADDING = 200
$ = jQuery
TEMPLATES =
  category: '''
  <div class="language-group">
     <div class="language-group-header">{{name}}</div>
     <ul>
      {{#languages}}
       <li><a data-langname="{{name}}">{{{formatted}}}</a></li>
      {{/languages}}
     </ul>
  </div>
  '''
  languageMenu: '''
  <div class="overlay-header">Supported Languages</div>
     {{#categories}}
      {{>category}}
    {{/categories}}

  '''
  examples: '''
    <div class="titles">
      <a class="button selected" data-which="editor"> Editor Examples </a>
      <a class="button" data-which="console"> Console Examples </a>
    </div>
    <div class="layer"></div>
    <ul class="editor">
    {{#editor}}
      <li><a href="#" class="example-button">{{title}}</a></li>
    {{/editor}}
    </ul>
    <ul class="console" style="display:none;">
    {{#console}}
      <li><a href="#" class="example-button">{{title}}</a></li>
    {{/console}}
    </ul>
  '''
LANG_CATEGORIES = [
  ['Classic', ['QBasic', 'Forth', 'Smalltalk']]
  ['Practical', ['Scheme', 'Lua', 'Python']]
  ['Esoteric', ['LOLCODE', 'Brainfuck', 'Emoticon', 'Bloop', 'Unlambda']]
  ['Web', ['JavaScript', 'Traceur', 'CoffeeScript', 'Kaffeine', 'Move']]
]

REPLIT =
  # jQuery elems.
  $container: null
  $consoleContainer: null
  $editorContainer: null
  $console: null
  $editor: null
  $resizer: null
  # Editor to console
  split_ratio: .5

  examples:
    editor: []
    console: []

  InitDOM: ->
    @$container = $('#content')
    @$editorContainer = $('#editor')
    @$consoleContainer = $('#console')
    @$resizer =
      l: $('#resize-left')
      c: $('#resize-center')
      r: $('#resize-right')
    @$throbber = $('#throbber')
    # Initialaize the column resizer.
    REPLIT.InitResizer()
    # Fire the onresize method to do initial resizing
    REPLIT.OnResize()
    $(window).bind 'resize',-> REPLIT.OnResize()

    # Attatches the resizer behavior.
  InitResizer: ->

    $.fn.disableSelection = ->
      @each ->
        $this = $(this)
        $this.attr 'unselectable', 'on'
        $this.css
          '-moz-user-select':'none'
          '-webkit-user-select':'none'
          'user-select':'none'
        $this.each -> this.onselectstart = -> return false

    $.fn.enableSelection = ->
      @each ->
        $this = $(this)
        $this.attr 'unselectable', ''
        $this.css
          '-moz-user-select': ''
          '-webkit-user-select': ''
          'user-select': ''
        $this.each -> this.onselectstart = null

    mousemove = (e) =>
      left = e.pageX - (CONTENT_PADDING / 2) + 8
      @split_ratio = left / @$container.width()
      @OnResize()

    $body = $('body')
    mouse_release = ->
      $body.enableSelection()
      $body.unbind 'mousemove.replit'

    @$resizer.l.mousedown (e) =>
      if e.button == 0
        $body.disableSelection()
        # Name space the event so we can safely unbind.
        $body.bind 'mousemove.replit', (e) =>
          CONTENT_PADDING = ((e.pageX - 4) * 2)
          @OnResize()

    @$resizer.l.mouseup mouse_release


    @$resizer.r.mousedown (e) =>
      if e.button == 0
        $body.disableSelection()
        $body.bind 'mousemove.replit', (e) =>
          CONTENT_PADDING = ($body.width() - e.pageX - 4) * 2
          @OnResize()

    @$resizer.r.mouseup mouse_release

    @$resizer.c.mousedown (e) =>
      if e.button == 0
        @$container.disableSelection()
      @$container.mousemove mousemove

    release = =>
      @$container.enableSelection()
      @$container.unbind 'mousemove'

    @$resizer.c.mouseup release
    @$container.mouseup release
    @$container.mouseleave release

  # Resize containers on each window resize.
  OnResize: ->
    width = document.documentElement.clientWidth - CONTENT_PADDING
    # 50 for header.
    height = document.documentElement.clientHeight - 61 - 40
    editor_width = @split_ratio * width
    console_width = width - editor_width

    @$resizer.c.css 'left', editor_width - 8
    @$container.css
      width: width
      height: height
    @$editorContainer.css
      width: editor_width - 16
      height: height
    @$consoleContainer.css
      width: console_width
      height: height
    # Call to resize environment if the app has already initialized.
    REPLIT.EnvResize() if @inited

  # Calculates editor and console dimensions according to their parents and
  # neighboring elements (if any).
  EnvResize: ->
    # Calculate real height.
    console_hpadding = @$console.innerWidth() - @$console.width()
    console_vpadding = @$console.innerHeight() - @$console.height()
    editor_hpadding = @$editor.innerWidth() - @$editor.width()
    # + 30 for the control menu above the editor.
    editor_vpadding = @$editor.innerHeight() - @$editor.height()

    @$console.css 'width', @$consoleContainer.width() - console_hpadding
    @$console.css 'height', @$consoleContainer.height() - console_vpadding
    @$editor.css 'width', @$editorContainer.innerWidth() - editor_hpadding
    @$editor.css 'height', @$editorContainer.innerHeight() - editor_vpadding
    @editor.resize()

  InitButtons: ->
    $('#button-examples').click (e) =>
      e.preventDefault()
      REPLIT.ShowExamplesOverlay()

    $('#button-languages').click (e) =>
      e.preventDefault()
      REPLIT.ShowLanguagesOverlay()

  InjectSocial: ->
    # Some of this is fucking with Ace's loading so we dynamically inject the
    # social shit. Facebook doesn't like being injected so it gets a special
    # treatment.
    # TODO(amasad): Use the actual async scripts provided by Google/FB/Twitter.
    #               These are just design no-ops.
    html = """
    <!-- Google+ -->
    <div class="social_button" type="google">
      <script type="text/javascript" src="https://apis.google.com/js/plusone.js"></script>
      <g:plusone size="medium"></g:plusone>
    </div>
    <!-- Twitter -->
    <div class="social_button" type="twitter">
      <a href="http://twitter.com/share" class="twitter-share-button" data-text="Testing out the twitter button." data-url="http://localhost" data-count="horizontal" data-via="Localhost">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
    </div>
    <!-- Hacker News -->
    <a href="http://news.ycombinator.com/submitlink?u=&amp;t=http://localhost/" class="social_button">
      <img src="images/hnlike.png" />
    </a>
    """
    $('#social-buttons-container').append(html)

  Init: ->
    @jsrepl = new JSREPL {
      InputCallback: $.proxy @InputCallback, @
      OutputCallback: $.proxy @OutputCallback, @
      ResultCallback: $.proxy @ResultCallback, @
      ErrorCallback: $.proxy @ErrorCallback, @
    }
    # Init console.
    @jqconsole = @$consoleContainer.jqconsole '', '> '
    @$console = @$consoleContainer.find '.jqconsole'

    # Init editor.
    @editor = ace.edit 'editor-widget'
    @editor.setTheme 'ace/theme/textmate'
    @editor.renderer.setHScrollBarAlwaysVisible false
    @$editor = @$editorContainer.find '#editor-widget'
    $run = $('#editor-run');
    $run.click =>
      @jqconsole.AbortPrompt()
      @jsrepl.Evaluate REPLIT.editor.getSession().getValue()
    @$editorContainer.hover ->
      $run.fadeToggle 'fast'
    @$editorContainer.mousemove ->
      $run.fadeIn 'fast'
    @$editorContainer.keydown ->
      $run.fadeOut 'fast'

    @current_lang = null

    # Render language selection templates.
    templateCategories = []
    for [categoryName, languages] in LANG_CATEGORIES
      templateLanguages = []
      for lang in languages
        display_name = @Languages[lang].name
        shortcutIndex = display_name.indexOf @Languages[lang].shortcut
        formattedShortcut = "<em>#{display_name.charAt(shortcutIndex)}</em>"
        formatted = display_name[...shortcutIndex] + formattedShortcut + display_name[shortcutIndex + 1...]
        templateLanguages.push {name:lang, formatted}
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
    @$throbber.show()
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

        #Load ace mode.
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

        # Load examples.
        parseExamples = (raw_examples)->
          # Clear the existing examples.
          examples = []
          # Parse out the new examples.
          example_parts = raw_examples.split /\*{80}/
          title = null
          for part in example_parts
            part = part.replace /^\s+|\s*$/g, ''
            if not part then continue
            if title
              code = part
              examples.push {
                title
                code
              }
              title = null
            else
              title = part
          return examples

        examples_config = @Languages[lang_name].examples
        $.when($.get(examples_config.console),
        $.get(examples_config.editor)).done (consoleArgs, editorArgs) =>
          @examples.console = parseExamples consoleArgs[0]
          @examples.editor = parseExamples editorArgs[0]
          examples_sel_html = Mustache.to_html TEMPLATES.examples, @examples
          $('#examples-selector').empty().append examples_sel_html


        # Empty out the history, prompt and example selection.
        @jqconsole.Reset()
        # Register charecter matchings in jqconsole for the current language
        i = 0
        for [open, close] in @current_lang.matchings
          @jqconsole.RegisterMatching open, close, 'matching-' + (++i)
        
        @jqconsole.RegisterShortcut 'Z', =>
          @jqconsole.AbortPrompt()
          @StartPrompt()
        @jsrepl.LoadLanguage lang_name, =>
          $('body').toggleClass 'loading'
          @$throbber.hide()
          @StartPrompt()

  # Langauge selection overlay method.
  ShowLanguagesOverlay: ->
    $doc = $(document)
    selected = false
    jQuery.facebox {div: '#language-selector'}, 'languages overlay'
    select = ($elem) =>
      $doc.trigger 'close.facebox'
      selected = true
      @LoadLanguage $elem.data 'langname'

    $('#facebox .content.languages em').each (i, elem) =>
      $elem = $(elem)
      $doc.bind 'keyup.languages', (e) =>
        upperCaseCode = $elem.text().toUpperCase().charCodeAt(0)
        lowerCaseCode = $elem.text().toLowerCase().charCodeAt(0)
        if e.keyCode == upperCaseCode or e.keyCode == lowerCaseCode
          select $elem.parent()

    $('#facebox .content.languages a').click ->
      select $(this)

    $doc.bind 'close.facebox.languages', =>
      $doc.unbind 'keyup.languages'
      $doc.unbind 'close.facebox.languages'
      @StartPrompt() if not selected

    @jqconsole.AbortPrompt() if @jqconsole.state == 2

  ShowExamplesOverlay: ->
    jQuery.facebox {div: '#examples-selector'}, 'examples overlay'
    that = @
    $examples = $('#facebox .content.examples');
    $examples.find('.titles .button').click (e) ->
      $this = $(this)
      $selected = $examples.find('.selected')
      return if $this == $selected
      $selected.removeClass 'selected'
      $this.addClass 'selected'
      $examples.find("ul.#{$selected.data('which')}").hide()
      $examples.find("ul.#{$this.data('which')}").show()

    $examples.delegate 'ul a.example-button', 'click', (e) ->
      e.preventDefault()
      $this = $(this)
      if $this.parents('ul').is('.editor')
        that.editor.getSession().setValue that.examples['editor'][$this.parent().index()].code
      else
        that.jqconsole.SetPromptText that.examples['console'][$this.parent().index()].code
      $(document).trigger 'close.facebox'

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
    if typeof error == 'object'
      error = error.message
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

$ ->
  REPLIT.InitDOM()

  JSREPLLoader.onload =>
    REPLIT.Init()
    # At this stage the actual environment elements are available, resize them.
    REPLIT.EnvResize()
    REPLIT.InitButtons()
    REPLIT.InjectSocial()
    $(document).keyup (e)->
      # Escape key
      if e.keyCode == 27 and not $('#facebox').is(':visible')
        REPLIT.ShowLanguagesOverlay()

# Export globally.
@REPLIT = REPLIT

$(window).load ->
  # Hack for chrome and FF 4 fires an additional popstate on window load.
  setTimeout (-> REPLIT.SetupURLHashChange()), 0

