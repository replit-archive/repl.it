$ ->
  page '/', ->
    REPLIT.OpenPage 'workspace'

  page '/examples', ->
    if REPLIT.current_lang? and REPLIT.jqconsole.GetState() is 'prompt'  # STATE_PROMPT
      $('#examples-editor').toggle REPLIT.split_ratio != REPLIT.EDITOR_HIDDEN
      $('#examples-console').toggle REPLIT.split_ratio != REPLIT.CONSOLE_HIDDEN
      REPLIT.OpenPage 'examples'

  page '/about', ->
    REPLIT.OpenPage 'about'

  page '/help', -> 
    REPLIT.OpenPage 'help'

  page '/languages', ->
    REPLIT.OpenPage 'languages'

  page '/languages/:lang', (context) ->
    if lang = context.params.lang
      REPLIT.OpenPage 'workspace'
      return if REPLIT.current_lang_name is lang
      REPLIT.current_lang_name = lang
      REPLIT.LoadLanguage lang

  # Catch-all for sessions:
  # When we are in a session the base url is the session name.
  prev_base = null
  page '/:name/:num?', (context) ->
    {name, num} = context.params
    #[_, name, num] = context.canonicalPath.match /^\/([^\/]+)(?:\/(\d+)\/?)?/
    return if not name
    base = "/#{name}"
    base += "/#{num}" if num
    page.base base
    $('a').each ->
      href = $(@).attr('href')
      if href[0] is '/'
        console.log prev_base, href
        href = href.replace "#{prev_base}", '' if prev_base
        $(@).attr 'href', "#{base}/#{href.substr(1)}"
    prev_base = base
  page()

loc = window.location
window.Router =
  navigate: (path) ->
    return if loc.pathname is path
    page path
