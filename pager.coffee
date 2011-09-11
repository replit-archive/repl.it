# Extension module.
# Responsible for page opening/closing/stacking.

$ = jQuery

ANIMATION_DURATION = 300
KEY_ESCAPE = 27
FIRST_LOAD = true

LANG_TEMPLATE =
  language_group: (data) ->
    {category, languages} = data
    """
    <div class="language-group">
      <div class="language-group-header">#{category}</div>
        <ul>
          #{(@language_entry(language) for language in languages).join('')}
        </ul>
      </div>
    </div>
  """

  language_entry: (data) ->
    {name, shortcut, system_name, tagline} = data
    shortcut_index = name.indexOf(shortcut)
    """
      <li data-lang="#{system_name}">
        <b>#{name[0...shortcut_index]}<em>#{shortcut}</em>#{name[shortcut_index + 1...]}:</b>&nbsp;
          #{tagline}
      </li>
    """

  render: ->
    html = []
    categories_order = [
      'Classic'
      'Practical'
      'Esoteric'
      'Web'
    ]
    template_data =
      Classic:
        category: 'Classic'
        languages: ['QBasic', 'Forth']
      Practical:
        category: 'Practical'
        languages: ['Python', 'Lua', 'Scheme']
      Esoteric:
        category: 'Esoteric'
        languages: ['Emoticon', 'Brainfuck', 'LOLCODE', 'Unlambda', 'Bloop']
      Web:
        category: 'Web'
        languages: ['JavaScript', 'Traceur', 'Move', 'Kaffeine', 'CoffeeScript']

    for _, category of template_data
      for lang_name, index in category.languages
        lang = REPLIT.Languages[lang_name]
        lang.system_name = lang_name
        category.languages[index] = lang
    for category in categories_order
      html.push @language_group template_data[category]

    return html.join ''

PAGES =
  workspace:
    id: 'content-workspace'
    title: '$'
    min_width: 500
    width: 1000
    max_width: 3000
  languages:
    id: 'content-languages'
    title: 'Select a Language'
    min_width: 1030
    width: 1030
    max_width: 1400
  examples:
    id: 'content-examples'
    title: '$ Examples'
    min_width: 1000
    width: 1000
    max_width: 1400
  help:
    id: 'content-help'
    title: 'Help'
    min_width: 1000
    width: 1000
    max_width: 1400
  about:
    id: 'content-about'
    title: 'About Us'
    min_width: 600
    max_width: 600
    width: 600

$.extend REPLIT,
  LoadExamples: (file, container, callback) ->
    $examples_container = $ '#examples-' + container
    $('.example-group').remove()
    $.get file, (contents) =>
      # Parse examples.
      raw_examples = contents.split /\*{60,}/
      index = 0
      total = Math.floor raw_examples.length / 2
      while index + 1 < raw_examples.length
        name = raw_examples[index].replace /^\s+|\s+$/g, ''
        code = raw_examples[index + 1].replace /^\s+|\s+$/g, ''
        # Insert an example element and set up its click handler.
        example_element = $ """
          <div class="example-group example-#{total}">
            <div class="example-group-header">#{name}</div>
            <code>#{code}</code>
          </div>
        """
        $examples_container.append example_element
        example_element.click -> callback $('code', @).text()
        index += 2

  # The pages stacking on the screen.
  page_stack: []
  # Whether we are currently changing a page (to prevent interference).
  changing_page: false

  # Open a page by its name.
  OpenPage: (page_name, callback=$.noop) ->
    if @changing_page then return
    @changing_page = true
    page = PAGES[page_name]
    current_page = @page_stack[@page_stack.length - 1]

    # If the page actually exists and it's not the current one.
    if not page or current_page is page_name
      @changing_page = false
    else
      # Calculate and set title.
      lang_name = if @current_lang_name
        @Languages[@current_lang_name].name
      else
        ''
      $title = $ '#title'
      new_title = page.title.replace /\$/g, lang_name
      if current_page
        $title.fadeOut ANIMATION_DURATION, ->
          $title.text new_title
          $title.fadeIn ANIMATION_DURATION
      else
        $title.text new_title

      # Update widths to those of the new page.
      # We can't take into account mobile sizes, so just assign the whole screen
      # width. Thats ok, since our mobile layout is fit to width.
      @min_content_width = if @ISMOBILE
        document.documentElement.clientWidth - 2 * @RESIZER_WIDTH
      else
        page.min_width
      @max_content_width = page.max_width
      
      # When the workspace is first loaded, don't mess up its default padding.
      if FIRST_LOAD and page_name is 'workspace'
        FIRST_LOAD = false
        @content_padding = @DEFAULT_CONTENT_PADDING
      else
        @content_padding = document.documentElement.clientWidth - page.width

      # Check if the page exists on our stack, if so splice out to be put
      # on top.
      index = @page_stack.indexOf page_name
      if index > -1
        @page_stack.splice index, 1
      # Put the page on top of the stack.
      @page_stack.push page_name

      # Calculate container width.
      outerWidth = page.width
      # HACK: Workspace doesn't account for resizers for some reason...
      if page_name isnt 'workspace' then outerWidth += 2 * @RESIZER_WIDTH

      done = =>
        @changing_page = false
        page.$elem.focus()
        callback()
      
      if current_page
        # Perform the animation.
        PAGES[current_page].width = $('.page:visible').width()
        PAGES[current_page].$elem.fadeOut ANIMATION_DURATION, =>
          @$container.animate width: outerWidth, ANIMATION_DURATION, =>
            # We need to have the box actually displayed (if invisible) so the
            # width calculations inside OnResize() work.
            page.$elem.css width: page.width, display: 'block', opacity: 0
            @OnResize()
            page.$elem.animate opacity: 1, ANIMATION_DURATION, done
      else
        @$container.css width: outerWidth
        page.$elem.css width: page.width, display: 'block'
        @OnResize()
        done()

  # Close the top page and opens the page underneath if exists or just animates
  # Back to the original environment width.
  CloseLastPage: ->
    if @changing_page then return
    if @page_stack.length <= 1 then return
    closed_page = @page_stack[@page_stack.length - 1]
    @OpenPage @page_stack[@page_stack.length - 2], =>
      @page_stack.splice @page_stack.indexOf(closed_page), 1

$ ->
  # Render language selector.
  $('#content-languages').append LANG_TEMPLATE.render()

  # Load Examples
  REPLIT.$this.bind 'language_loading', (_, system_name) ->
    examples = REPLIT.Languages[system_name].examples
    if not REPLIT.ISMOBILE
      REPLIT.LoadExamples examples.editor, 'editor', (example) ->
        REPLIT.editor.getSession().doc.setValue example
        REPLIT.OpenPage 'workspace', ->
          REPLIT.editor.focus()
    REPLIT.LoadExamples examples.console, 'console', (example) ->
      REPLIT.jqconsole.SetPromptText example
      REPLIT.OpenPage 'workspace', ->
        REPLIT.jqconsole.Focus()

  # Since we will be doing lots of animation and syncing, we better cache the
  # jQuery elements.
  for name, settings of PAGES
    settings.$elem = $("##{settings.id}")
    # If we are on a mobile set all default widths to 0 to invoke resizing
    # to the minimum which is already set to the width;
    if REPLIT.ISMOBILE and name isnt 'workspace' then settings.width = 0

  # Assign events.
  $body = $ 'body'
  $body.delegate '.page-close', 'click', -> REPLIT.CloseLastPage()
  $body.delegate '.language-group li', 'click', ->
    REPLIT.current_lang_name = $(@).data 'lang'
    REPLIT.OpenPage 'workspace', =>
      REPLIT.LoadLanguage REPLIT.current_lang_name

  # Bind page buttons.
  $('#button-examples').click ->
    if REPLIT.current_lang?
      $('#examples-editor').toggle REPLIT.split_ratio != REPLIT.EDITOR_HIDDEN
      $('#examples-console').toggle REPLIT.split_ratio != REPLIT.CONSOLE_HIDDEN
      REPLIT.OpenPage 'examples'
  $('#button-languages').click ->
    REPLIT.OpenPage 'languages'
  $('#link-about').click ->
    REPLIT.OpenPage 'about'
  $('#button-help').click ->
    REPLIT.OpenPage 'help'

  # Bind page closing to Escape.
  $(window).keydown (e) ->
    if e.which == KEY_ESCAPE and $('.page:visible') isnt '#content-workspace'
      REPLIT.CloseLastPage()

  # Bind language selector hotkeys.
  $('#content-languages').keypress (e) ->
    if e.shiftKey or e.ctrlKey or e.metaKey then return
    letter = String.fromCharCode(e.which).toLowerCase()
    $('#content-languages li').each ->
      if $('em', $ @).text().toLowerCase() == letter
        $(@).click()
        return false
