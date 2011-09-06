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
    html = ''
    categories_order = [
      'Classic'
      'Practical'
      'Esoteric'
      'Web' 
    ]
    template_data =
      Classic: 
        category: 'Classic'
        languages: []
      Practical: 
        category: 'Practical'
        languages: []
      Esoteric:
        category: 'Esoteric'
        languages: []
      Web:
        category: 'Web'
        languages: []
      
    for lang_name, lang of REPLIT.Languages
      lang.system_name = lang_name
      template_data[lang.category].languages.push lang
    
    for category in categories_order
      html += @language_group template_data[category]
    
    return html


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
FADE_DURATION = 200
# TODO(amasad): Export from the DOM module.
RESIZER_WIDTH = 8
# The minimum offset.
ZINDEX_OFFSET = 11

$.extend REPLIT,
  # The pages stacking on the screen.
  pages_stack: []
  # Open a page by its name.
  OpenPage: (page_name) ->
    # Get the page
    page = PAGES[page_name]
    if page
      @SetTitle page.title
      # Hide current page if exists.
      @pages_stack.$current()?.fadeOut FADE_DURATION * 4
      # Set the minimum width of the content space to the minimum width
      # specified by the page settings above.
      @min_content_width = page.min_width or @min_content_width
      # Check if the page exists on our stack, if so splice out to be put
      # on top.
      index = @pages_stack.indexOf page
      if index > -1
        @pages_stack.splice index, 1
      # Put the page on top of the stack
      @pages_stack.push page
      # Show the last stacked page.
      @pages_stack.$current().fadeIn FADE_DURATION
      # Resize the container to the minimum width specified by the page in question.
      if @$container.width() < page.min_width
        # Do initial syncing.
        @SyncPages()
        # Start animating the container to the minimum width.
        @$container.animate width: page.min_width,
          duration: ANIMATION_DURATION
          # On each step syncpages.
          step: => @SyncPages()
          # Don't queue animations just execute them.
          queue:false
        # Sync pages before animating the top stacked page.
        @SyncPages()
        # Animate the top stacked page so it follows the container with no delay.
        @pages_stack.$current().animate width: page.min_width - (RESIZER_WIDTH * 2),
          duration: ANIMATION_DURATION
          queue: false
          step: => @SyncPages()
          # As a precaution resync everything upon animation completion.
          complete: $.proxy(@SyncPages, @)
          
      else
        # Sync the pages.
        @SyncPages()
  
  # Close the top page.
  CloseLastPage: ->
    @pages_stack.pop().$elem.hide()
    @min_content_width = @pages_stack.current()?.min_width or PAGES.main.min_width
    @SetTitle @pages_stack.current()?.title or PAGES.main.title
    @OnResize(true)
  
  # Sync all pages with the container.
  SyncPages: ->
    $.each @pages_stack, (i, page) =>
      page.$elem.css
        width: @$container.width() - (RESIZER_WIDTH * 2)
        top: @$container.offset().top
        left: @$container.offset().left + RESIZER_WIDTH
        # TODO(amasad): Find another way, this is stupid!
        'z-index': ZINDEX_OFFSET++
    
# Gets the top page jQuery elem. 
REPLIT.pages_stack.$current = -> @[@length - 1]?.$elem
# Gets the top page settings.
REPLIT.pages_stack.current = -> @[@length - 1]

$ ->
  $('#content-languages').append LANG_TEMPLATE.render()
  # Sync pages each time REPLIT resizes.
  REPLIT.$this.bind 'resize', REPLIT.SyncPages
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
  
  