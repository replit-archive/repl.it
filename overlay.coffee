# Responsible for setting up and populating overlays.
# Also responsible for loading example files.

# Extension module.

# Note: A little bit messy since all this is probably going to change.

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

$.extend REPLIT,
  examples:
    editor: []
    console: []
    
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
        REPLIT.editor.getSession().setValue REPLIT.examples['editor'][$this.parent().index()].code
      else
        REPLIT.jqconsole.SetPromptText REPLIT.examples['console'][$this.parent().index()].code
      $(document).trigger 'close.facebox'

      REPLIT.jqconsole.Focus()

$ ->
  $('#button-examples').click (e) =>
    e.preventDefault()
    REPLIT.ShowExamplesOverlay()

  $('#button-languages').click (e) =>
    e.preventDefault()
    REPLIT.ShowLanguagesOverlay()
    
  $(document).keyup (e)->
    # Escape key
    if e.keyCode == 27 and not $('#facebox').is(':visible')
      REPLIT.ShowLanguagesOverlay()
  
  # Render language selection templates.
  templateCategories = []
  for [categoryName, languages] in LANG_CATEGORIES
    templateLanguages = []
    for lang in languages
      display_name = REPLIT.Languages[lang].name
      shortcutIndex = display_name.indexOf REPLIT.Languages[lang].shortcut
      formattedShortcut = "<em>#{display_name.charAt(shortcutIndex)}</em>"
      formatted = display_name[...shortcutIndex] + formattedShortcut + display_name[shortcutIndex + 1...]
      templateLanguages.push {name:lang, formatted}
    templateCategories.push {name: categoryName, languages: templateLanguages}
  lang_sel_html = Mustache.to_html TEMPLATES.languageMenu, {categories: templateCategories}, TEMPLATES
  $('#language-selector').append lang_sel_html
  
  REPLIT.$this.bind 'language_loading', (e, lang_name) ->
    # Parses an example file into a set of named examples array.
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

    examples_config = REPLIT.Languages[lang_name].examples
    $.when($.get(examples_config.console),
    $.get(examples_config.editor)).done (consoleArgs, editorArgs) ->
      REPLIT.examples.console = parseExamples consoleArgs[0]
      REPLIT.examples.editor = parseExamples editorArgs[0]
      examples_sel_html = Mustache.to_html TEMPLATES.examples, REPLIT.examples
      $('#examples-selector').empty().append examples_sel_html
    
