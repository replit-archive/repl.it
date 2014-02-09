# Extension module.
# Responsible for page opening/closing/stacking.

$ = jQuery

ANIMATION_DURATION = 300
KEY_ESCAPE = 27
FIRST_LOAD = true

PAGES =
  workspace:
    id: 'content-workspace'
    min_width: 500
    width: 1000
    max_width: 3000
    path: '/'
  languages:
    id: 'content-languages'
    min_width: 1080
    width: 1080
    max_width: 1400
    path: '/languages'
  examples:
    id: 'content-examples'
    min_width: 1000
    width: 1000
    max_width: 1400
    path: '/examples'
  help:
    id: 'content-help'
    min_width: 1000
    width: 1000
    max_width: 1400
    path: '/help'
  about:
    id: 'content-about'
    min_width: 600
    max_width: 600
    width: 600
    path: '/about'
  DEFAULT: 'workspace'

ALLOWED_IN_MODAL = ['help', 'about', 'languages']

$.extend REPLIT,
  PAGES: PAGES
  modal: false
  Modal: (@modal)->
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
    return if @modal and page_name not in ALLOWED_IN_MODAL
    page = PAGES[page_name]
    current_page = @page_stack[@page_stack.length - 1]
    # If the page actually exists and it's not the current one.
    if not page or current_page is page_name
      @changing_page = false
    else if @changing_page
      # Interrupt current page switching animation.
      $('.page').stop true, true
      @$container.stop true, true
      @changing_page = false
      # Retry openning the page.
      @OpenPage page_name
    else
      @changing_page = true
      # Calculate and set title.
      lang_name = if @current_lang_name
        @Languages[@current_lang_name.toLowerCase()].name
      else
        ''
      if page_name != 'workspace'
        new_title = page.$elem.find('.content-title').hide().text()
        REPLIT.changeTitle new_title
      else
        REPLIT.changeTitle REPLIT.current_lang_name

      # Update widths to those of the new page.
      # We can't take into account mobile sizes, so just assign the whole screen
      # width. That's Ok, since our mobile layout fits the whole width.
      @min_content_width = if @ISMOBILE
        document.documentElement.clientWidth - 2 * @RESIZER_WIDTH
      else
        page.min_width
      @max_content_width = page.max_width

      # When the workspace is first loaded, don't mess up its default padding.
      if FIRST_LOAD and page_name is 'workspace'
        FIRST_LOAD = false
        page.width = document.documentElement.clientWidth - @DEFAULT_CONTENT_PADDING
      @content_padding = document.documentElement.clientWidth - page.width

      # Check if the page exists on our stack. If so splice out to be put
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
        # HACK: Workspace doesn't account for resizers for some reason..
        if current_page is 'workspace'
          PAGES[current_page].width += 2 * @RESIZER_WIDTH
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
    if @page_stack.length <= 1
      Router.navigate '/'
    else
      closed_page = @page_stack[@page_stack.length - 1]
      Router.navigate PAGES[@page_stack[@page_stack.length - 2]].path
      @page_stack.splice @page_stack.indexOf(closed_page), 1

$ ->
  # Render language selector.

  # Load Examples
  REPLIT.$this.bind 'language_loading', (_, system_name) ->
    examples = REPLIT.Languages[system_name.toLowerCase()].examples
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

  # Bind page closing to Escape.
  $(window).keydown (e) ->
    if e.which == KEY_ESCAPE and $('.page:visible') isnt '#content-workspace'
      REPLIT.CloseLastPage()

  # Bind language selector hotkeys.
  $('#content-languages').keypress (e) ->
    if e.shiftKey or e.ctrlKey or e.metaKey then return
    letter = String.fromCharCode(e.which).toLowerCase()
    $('#content-languages li a').each ->
      if $('em', $ @).text().toLowerCase() == letter
        @click()
        return false
