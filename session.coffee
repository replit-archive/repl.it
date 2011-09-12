# Extension module.
# Encapsulates for all session/state loading saving logic.
# TODO(amasad): Graceful localStorage degrading to cookies.
# TODO(amasad): Don't depend on pushState and window location for sharing.

$ = jQuery

SHARE_TEMPLATE =
  twitter: ->
    text = 'Check out my REPL session - '
    related = 'replit'
    url = window.location.href
    uri = $.param {
      text
      url
      related
    }
    """
      <a href="https://twitter.com/share?#{uri}" target="_blank"></a>
    """

  facebook: ->
    """
      <a href="javascript:var d=document,f='http://www.facebook.com/share',l=d.location,e=encodeURIComponent,p='.php?src=bm&v=4&i=1315186262&u='+e(l.href)+'&t='+e(d.title);1;try{if (!/^(.*\.)?facebook\.[^.]*$/.test(l.host))throw(0);share_internal_bookmarklet(p)}catch(z) {a=function() {if (!window.open(f+'r'+p,'sharer','toolbar=0,status=0,resizable=1,width=626,height=436'))l.href=f+p};if (/Firefox/.test(navigator.userAgent))setTimeout(a,0);else{a()}}void(0)"></a>
    """

  #unofficial!
  gplus: ->
    text = 'Check out my REPL session - ' + window.location.href
    text = encodeURI text
    """
      <a href="https://m.google.com/app/plus/x/bggo8s9j8yqo/?v=compose&content=#{text}&login=1&pli=1&hideloc=1" target="_blank"></a>
    """

$.extend REPLIT,
  session:
    eval_history: []

# Resets application to its initial state (handler for language_loaded event).
reset_state = (e, lang_name) ->
  localStorage.setItem 'lang_name', lang_name
  $('#replay-button').hide()
  history.pushState null, null, '/'
  @session = {}
  @session.eval_history = []

$ ->
  # If there exist a REPLIT_DATA variable then we are in a saved session.
  if REPLIT_DATA?
    # Load the language specified by the incoming session data.
    REPLIT.OpenPage 'workspace', ->
      REPLIT.LoadLanguage REPLIT_DATA.language, ->
        # Set the editor text.
        REPLIT.editor.getSession().setValue REPLIT_DATA.editor_text if not @ISMOBILE
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
      REPLIT.current_lang_name = lang_name
      REPLIT.OpenPage 'workspace', ->
        REPLIT.LoadLanguage lang_name
    else
      # This a first visit, show language overlay.
      REPLIT.OpenPage 'languages'

  # Click handler for the replay button
  $('#replay-button').click (e) ->
    # Get the history comming from the server
    history = REPLIT.session.saved_eval_history
    locked = false
    locked_queue = []
    index = -1
    # Executes a command from history and waits for the result to continue
    # with the next command.
    handler = ->
      if not locked
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
      else
        locked_queue.push handler
   
    input_lock = ->
      locked = true
    
    input_unlock = ->
      locked = false
      fn = locked_queue.shift()
      setTimeout fn, 100 if fn?
      
    REPLIT.$this.bind 'result', handler
    REPLIT.$this.bind 'error', handler
    REPLIT.$this.bind 'input', input_unlock
    REPLIT.$this.bind 'input_request', input_lock
    # Initiate the first handler to start executing history commands.
    handler()
    # This button has to be click atmost once, now hide it.
    $(this).hide()

  $('#button-save').click (e) ->
    # Get the post data to save.
    post_data =
      lang_name: REPLIT.current_lang.system_name
      editor_text: REPLIT.editor.getSession().getValue() if not REPLIT.ISMOBILE
      eval_history: JSON.stringify REPLIT.session.eval_history

    # If we are already replin on a saved session get its id.
    post_data.id = REPLIT.session.id if REPLIT.session.id?
    # Do the actual save request.
    $.post '/save', post_data, (data) ->
      $savebox = $('#save-box')
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

      # Render social share links.
      console.log SHARE_TEMPLATE.twitter()
      $savebox.find('li.twitter a').replaceWith SHARE_TEMPLATE.twitter data
      $savebox.find('li.facebook a').replaceWith SHARE_TEMPLATE.facebook data
      $savebox.find('li.gplus a').replaceWith SHARE_TEMPLATE.gplus data
      $savebox.find('input').val window.location.href
      $savebox.slideDown()

  $('#save-box input').click -> $(this).select()
  # TODO(amasad): Make any click outside the box close it (a close button looks
  #               awful on such a small box).
  # When any command is evaled, save it in the eval_history array of the session
  # object, in order to send it to the server on save.
  REPLIT.$this.bind 'eval', (e, command) ->
    REPLIT.session.eval_history.push command
