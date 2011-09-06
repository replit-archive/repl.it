# Extension Module, depends on: Core.

# Responsible for page opening/closing/stacking.

$ = jQuery

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


# Constant page settings.
PAGES = 
  main: 
    id: 'content'
    title: ''
    min_width: 230
  languages: 
    id: 'content-languages'
    title: 'Languages Supported'
    min_width: 1030
  examples:
    id: 'content-examples'
    title: 'Examples'
    min_width: 1030
  help: 
    id: 'content-help'
    title: 'Help'
    min_width: 1030
  about: 
    id: 'content-about'
    title: 'About Us'
    min_width: 530

ANIMATION_DURATION = 700
FADE_DURATION = 300
# TODO(amasad): Export from the DOM module.
RESIZER_WIDTH = 8
# The minimum offset.
ZINDEX_OFFSET = 11

$.extend REPLIT,
  LoadExamples: (file, side) ->
    $examples_container = $('#content-examples .inner')
    $('.example-group').remove()
    $.get file, (contents) ->
      raw_examples = contents.split /\*{60,}/
      index = 0
      total = Math.floor raw_examples.length / 2
      while index + 1 < raw_examples.length
        name = raw_examples[index].replace /^\s+|\s+$/g, ''
        code = raw_examples[index + 1].replace /^\s+|\s+$/g, ''
        cls = "example-#{side} example-#{total}-#{1 + index / 2}"
        $examples_container.append """
          <div class="example-group #{cls}">
            <div class="example-group-header">#{name}</div>
            <code>#{code}</code>
          </div>
        """
        index += 2
        
  # The pages stacking on the screen.
  page_stack: []
  # The editor/console width before automatic resize.
  EnvWidth: null
  
  # Open a page by its name.
  OpenPage: (page_name, record_env_width=true) ->
    # We maybe given a page name or a page object.
    if typeof page_name == 'object'
      page = page_name
    else
      page = PAGES[page_name]
    
    # If the page actually exists and its not the current one.
    if page and @page_stack.current() isnt page
      @SetTitle page.title
      $current_page = @page_stack.$current()
      # Hide the current page if existed.
      $current_page?.fadeOut FADE_DURATION * 4
      # Record the container width if we are asked to.
      if record_env_width and not $current_page
        @EnvWidth = @$container.width() 
      
      # Set the minimum width of the content space to the minimum width
      # specified by the page settings above.
      @min_content_width = page.min_width or @min_content_width
      # Check if the page exists on our stack, if so splice out to be put
      # on top.
      index = @page_stack.indexOf page
      if index > -1
        @page_stack.splice index, 1
      # Put the page on top of the stack
      @page_stack.push page
      # Show the last stacked page.
      @page_stack.$current().fadeIn FADE_DURATION
      # Resize the container to the minimum width specified by the page in question.
      if @$container.width() < page.min_width
        # Do initial syncing.
        @SyncPages()
        # Start animating the container to the minimum width.
        @AnimateEnv page.min_width, (=> @SyncPages)
        # Sync pages before animating the top stacked page.
        @SyncPages()
        # Animate the top stacked page so it follows the container with no delay.
        @page_stack.$current().animate width: page.min_width - (RESIZER_WIDTH * 2),
          duration: ANIMATION_DURATION
          queue: false
          step: => @SyncPages()
          # As a precaution resync everything upon animation completion.
          complete: => @SyncPages()
      else
        # Sync the pages.
        @SyncPages()
  
  # Close the top page and opens the page underneath if exists or just animates
  # Back to the original environment width.
  CloseLastPage: ->
    $closed_page = @page_stack.pop().$elem
    curr_page = @page_stack.current()
    # Check if this is not the last page.
    if curr_page?
      @min_content_width = curr_page.min_width
      # Reopen this page.
      @page_stack.pop()
      $closed_page.fadeOut FADE_DURATION * 4
      @OpenPage curr_page, false
    else
      @OnResize()
      @min_content_width = PAGES.main.min_width
      $closed_page.fadeOut FADE_DURATION
      @AnimateEnv @EnvWidth
      @SetTitle @Languages[@current_lang.system_name].name
  
  # Animates the container and its guts to the specified size.
  AnimateEnv: (width, step=$.noop)->
    # The prompt keeps jiggling no matter what,
    # Best choice to hide it!
    @$console.hide()
    
    editor_width = (@split_ratio * width) -  (RESIZER_WIDTH * 1.5)
    console_width = ((1 - @split_ratio) * width) - (RESIZER_WIDTH * 1.5)
    # Change content_padding variable so, it would not snap back on window resize.
    @content_padding = document.documentElement.clientWidth - width
    
    num_anims = 5
    complete = =>
      if --num_anims == 0
        @EnvResize()
        @$console.fadeIn()
    anim_config = 
      duration: ANIMATION_DURATION
      step: step
      complete: complete
      
    @$resizer.c.animate left: editor_width + RESIZER_WIDTH, anim_config
    @$container.animate width: width, anim_config
    @$editorContainer.animate width: editor_width, anim_config
    @$consoleContainer.animate width: console_width, anim_config
    @$editor.animate width: editor_width, anim_config
        
  # Sync all pages with the container.
  SyncPages: ->
    $.each @page_stack, (i, page) =>
      page.$elem.css
        width: @$container.width() - (RESIZER_WIDTH * 2)
        top: @$container.offset().top
        left: @$container.offset().left + RESIZER_WIDTH
        # TODO(amasad): Find another way, this is stupid!
        'z-index': ZINDEX_OFFSET++
    
# Gets the top page jQuery elem. 
REPLIT.page_stack.$current = -> @[@length - 1]?.$elem
# Gets the top page settings.
REPLIT.page_stack.current = -> @[@length - 1]

$ ->
  # Render lanuage selector.
  $('#content-languages .inner').append LANG_TEMPLATE.render()
  
  # Sync pages each time REPLIT resizes.
  REPLIT.$this.bind 'resize', REPLIT.SyncPages
  # Load Examples
  REPLIT.$this.bind 'language_loading', (e, system_name) ->
    # TODO: Hide console/editor examples if only the editor/console is open,
    #       respectively.
    examples = REPLIT.Languages[system_name].examples
    REPLIT.LoadExamples examples.editor, 'left'
    REPLIT.LoadExamples examples.console, 'right'
    
  # Since were going to be doing lots of animation and syncing we better cache
  # the jquery elements.
  for name, settings of PAGES
    settings.$elem = $("##{settings.id}")
  # Assign events.
  $body = $('body')
  $body.delegate '.page-close', 'click', -> REPLIT.CloseLastPage()
  $body.delegate '.language-group li', 'click', -> 
    REPLIT.LoadLanguage $(this).data('lang')
    REPLIT.CloseLastPage()
  # Bind page buttons.
  $('#button-examples').click ->
    REPLIT.OpenPage 'examples'
  $('#button-languages').click ->
    REPLIT.OpenPage 'languages'
  $('#link-about').click ->
    REPLIT.OpenPage 'about'
  $('#button-help').click ->
    REPLIT.OpenPage 'help'
  
  