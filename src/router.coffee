$ ->
  page '/', ->
    REPLIT.OpenPage 'workspace'

  page '/examples', (context, next) ->
    if REPLIT.current_lang? and REPLIT.jqconsole.GetState() is 'prompt'
      $('#examples-editor').toggle REPLIT.split_ratio != REPLIT.EDITOR_HIDDEN
      $('#examples-console').toggle REPLIT.split_ratio != REPLIT.CONSOLE_HIDDEN
      REPLIT.OpenPage 'examples'
    else
      Router.navigate '/'

  page '/about', ->
    REPLIT.OpenPage 'about'

  page '/help', -> 
    REPLIT.OpenPage 'help'

  page '/languages', ->
    REPLIT.OpenPage 'languages'

  page '/languages/:lang', (context) ->
    # So we don't try to load from localStorage.
    REPLIT.url_language = true
    if lang = context.params.lang
      old_lang = REPLIT.current_lang_name
      REPLIT.current_lang_name = lang
      REPLIT.OpenPage 'workspace'
      if old_lang isnt lang
        REPLIT.LoadLanguage lang

  first_load = true
  page '/:name/:num?/:page_name?', (context) ->
    unless first_load
      # It's hard to reproduce old session state. Let's just reload the page.
      window.location.reload()
    else
      {name, num, page_name} = context.params
      if num and not num.match /\d+/
        page_name = num
        num = null
      first_load = false
      base = "/#{name}" 
      base += "/#{num}" if num
      Router.change_base base, false
      if page_name
        page "/#{page_name}" 
      else
        REPLIT.OpenPage 'workspace'

  page()

loc = window.location

replace_base = (href, old_base, new_base) ->
  href = href.replace old_base, ''
  href = href.substr(1) if href[0] is '/'
  href = "#{new_base}/#{href}"
  # Remove //, trailing slashes etc.
  '/' + href.split('/').filter((p) -> !!p).join('/')

window.Router =
  base: '/'

  navigate: (path, context) ->
    if loc.pathname isnt path
      page path

  change_base: (path, navigate=true) ->
    return if path is @base
    old_base = @base
    @base = path
    $('a').each ->
      href = $(@).attr('href')
      # Internal link.
      if href[0] is '/'
        $(@).attr 'href', replace_base href, old_base, path
    page.base @base
    page @base if navigate
