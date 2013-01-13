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

  page()

loc = window.location
window.Router =
  navigate: (path) ->
    return if loc.pathname is path
    page path
