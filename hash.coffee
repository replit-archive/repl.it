# Extension module.
# Responsible for generating cross-browser hash change events.

$ = jQuery

popStateSupported = 'onpopstate' of window
hashchangeSupported = 'onhashchange' of window
pushStateSupported = 'pushState' of history

$.extend REPLIT,
  HASH_SEPARATOR: ':'
  setHash: (target) ->
    if target[0] is '#' then target = target.slice 1
    if pushStateSupported
      history.pushState null, '', '#' + target
    else
      window.location.hash = target

$ ->
  if popStateSupported
    $(window).bind 'popstate', ->
      REPLIT.$this.trigger 'hashchange', [window.location.hash.slice 1]
  else if hashchangeSupported
    $(window).bind 'hashchange', ->
      REPLIT.$this.trigger 'hashchange', [window.location.hash.slice 1]
    # Emulate first hashchange.
    page = window.location.hash.slice 1
    if hash then REPLIT.$this.trigger 'hashchange', [hash]
  else
    lastHash = null
    checkHash = ->
      hash = window.location.hash.slice 1
      if hash isnt lastHash then REPLIT.$this.trigger 'hashchange', [hash]
    setInterval checkHash, 250
