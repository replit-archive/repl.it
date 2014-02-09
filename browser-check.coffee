# Adapted from jQuery migrate.
uaMatch = (ua) ->
  ua = ua.toLowerCase();

  match = /(chrome)[ \/]([\w.]+)/.exec(ua) or
    /(webkit)[ \/]([\w.]+)/.exec(ua) or
    /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua) or
    /(msie) ([\w.]+)/.exec(ua) or
    ua.indexOf('compatible') < 0 and /(mozilla)(?:.*? rv:([\w.]+)|)/.exec(ua) or
    []

  return {
    browser: match[ 1 ] || ''
    version: match[ 2 ] || '0'
  }


matched = uaMatch navigator.userAgent
browser = {};

if matched.browser
  browser[ matched.browser ] = true
  browser.version = matched.version
  if browser.chrome
    browser.webkit = true
  else if browser.webkit
    browser.safari = true

  jQuery.browser = browser

ISMOBILE = Boolean navigator.userAgent.match /iPhone|iPad|iPod|Android/i

if not ISMOBILE
  chromeVersion = navigator.userAgent.match /Chrome\/(\d+)/i
  safariVersion = navigator.userAgent.match /Version\/(\d+)/i
  if ((browser.msie and browser.version < 10.0) or
      (browser.mozilla and browser.version < 4) or
      (browser.opera and browser.version < 11.51) or
      (browser.safari and chromeVersion and chromeVersion[1] < 13) or
      (browser.safari and safariVersion and safariVersion[1] < 5))
    $ ->
      $('#content-fallback').show()
      $('#fallback-ignore').click -> $('#content-fallback').hide()

$.extend REPLIT,
  ISMOBILE: ISMOBILE
  ISIOS: Boolean navigator.userAgent.match /iPhone|iPad|iPod/i
