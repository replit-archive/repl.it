ISMOBILE = Boolean navigator.userAgent.match /iPhone|iPad|iPod|Android/i

if not ISMOBILE
  chromeVersion = navigator.userAgent.match /Chrome\/(\d+)/i
  safariVersion = navigator.userAgent.match /Version\/(\d+)/i
  if (($.browser.msie and $.browser.version < 10.0) or
      ($.browser.mozilla and $.browser.version < 4) or
      ($.browser.opera and $.browser.version < 11.51) or
      ($.browser.safari and chromeVersion and chromeVersion[1] < 13) or
      ($.browser.safari and safariVersion and safariVersion[1] < 5))
    $ ->
      $('#content-fallback').show()
      $('#fallback-ignore').click -> $('#content-fallback').hide()

$.extend REPLIT,
  ISMOBILE: ISMOBILE
  ISIOS: Boolean navigator.userAgent.match /iPhone|iPad|iPod/i
