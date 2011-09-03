# Encapsulates for all session/state loading saving logic.

# Extension module.

$ = jQuery

$.extend REPLIT,
  session:
    eval_history: []
    
# Resets application to its initial state (handler for language_loaded event).
reset_state = (e, lang_name) ->
  localStorage.setItem 'lang_name', lang_name
  history.pushState null, null, '/'
  @session = {}
  @session.eval_history = []
    
$ ->
  # If there exist a REPLIT_DATA variable then we are in a saved session.
  if REPLIT_DATA?
    # Load the language specified by the incoming session data.
    REPLIT.LoadLanguage REPLIT_DATA.language, () ->
      # Set the editor text.
      REPLIT.editor.getSession().setValue REPLIT_DATA.editor_text
      # Get the session data.
      REPLIT.session.id = REPLIT_DATA.id
      REPLIT.session.rid = REPLIT_DATA.rid
      REPLIT.session.saved_eval_history = REPLIT_DATA.eval_history
      # Show the replay button.
      $('#replay-button').show()
      # Delete the incoming session data from the server since we have extracted
      # everything we neeed.
      delete window['REPLIT_DATA']
      # On each language load after this one reset the state.
      REPLIT.$this.bind 'language_loaded', reset_state
  else
    # We are not in a saved session.
    # Safely bind the reset state function.
    REPLIT.$this.bind 'language_loaded', reset_state
    lang_name = localStorage.getItem('lang_name')
    if lang_name isnt null
      # We have a saved local settings for language to load.
      REPLIT.LoadLanguage lang_name
    else
      # This a first visit, show language overlay.
      REPLIT.ShowLanguagesOverlay()
  # Click handler for the replay button
  $('#replay-button').click (e) ->
    # Get the history comming from the server
    history = REPLIT.session.saved_eval_history
    index = -1
    # Executes a command from history and waits for the result to continue
    # with the next command.
    handler = =>
      index++
      if history[index]?
        # Set the prompt text to the command in question.
        REPLIT.jqconsole.SetPromptText history[index]
        # Remove multiline handler from jqconsole to ensure it doesnt' continue
        # to the next line.
        _multiline = REPLIT.jqconsole.multiline_callback
        REPLIT.jqconsole.multiline_callback = undefined
        # Simulate an enter button on jqconsole.
        REPLIT.jqconsole._HandleEnter()
        # Reassign the multiline handler.
        REPLIT.jqconsole.multiline_callback = _multiline
      else
        # There is no more commands, unbind the handler.
        REPLIT.$this.unbind 'result', handler
        REPLIT.$this.unbind 'error', handler
        # We are done from the eval history comming from the server, delete it.
        delete REPLIT.session['saved_eval_history']
    
    REPLIT.$this.bind 'result', handler
    REPLIT.$this.bind 'error', handler
    # Initiate the first handler to start executing history commands.
    handler()
    # This button has to be click atmost once, now hide it.
    $(this).hide()
    
  $('#button-save').click (e) ->
    # Get the post data to save.
    post_data =
      lang_name: localStorage.getItem 'lang_name'
      editor_text: REPLIT.editor.getSession().getValue()
      eval_history: JSON.stringify(REPLIT.session.eval_history)
    
    # If we are already replin on a saved session get its id.
    post_data.id = REPLIT.session.id if REPLIT.session.id?
    # Do the actual save request.
    $.post '/save', post_data, (data) ->
      if isFinite data
        # The data is a number, which means its a revision id, append it to
        # the current location.
        history.pushState null, null, "/#{location.pathname.split('/')[1]}/#{data}"
        # Save the rivision id in the session object.
        REPLIT.session.rid = data
      else
        # We just saved a regular session, append the urlhash to the window location.
        history.pushState null, null, data
        # Save the session id (urlhash) in the session object.
        REPLIT.session.id = data
  
  # When any command is evaled, save it in the eval_history array of the session
  # object, in order to send it to the server on save.
  REPLIT.$this.bind 'eval', (e, command) ->
    REPLIT.session.eval_history.push command
      
  