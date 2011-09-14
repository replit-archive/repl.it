# Extension module.
# Responsible for generating cross-browser hash change events.

$ = jQuery

popStateSupported = 'onpopstate' of window
hashchangeSupported = 'onhashchange' of window
pushStateSupported = 'pushState' of history
window_loaded = false
cherry_pop = true

$(window).bind 'load', ->
  window_loaded = true
  
$.extend REPLIT,
  HASH_SEPARATOR: ':'
  setHash: (target) ->
    cb = -> 
      window.location.hash = target
      REPLIT.$this.trigger 'hashchange', [window.location.hash.slice 1]
    if not window_loaded
      setTimeout (-> REPLIT.setHash target), 50
    else
      cb()
$(window).bind 'load', ->
  if hashchangeSupported
    $(window).bind 'hashchange', ->
      REPLIT.$this.trigger 'hashchange', [window.location.hash.slice 1]
      return true
    $(window).trigger 'hashchange'
  else if popStateSupported
    $(window).bind 'popstate', ->
      REPLIT.$this.trigger 'hashchange', [window.location.hash.slice 1]
      return true
    $(window).trigger 'popstate'
  else
    lastHash = null
    checkHash = ->
      hash = window.location.hash.slice 1
      if hash isnt lastHash then REPLIT.$this.trigger 'hashchange', [hash]
    setInterval checkHash, 250
