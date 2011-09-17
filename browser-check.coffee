chromeVersion = navigator.userAgent.match /Chrome\/(\d+)/i
safariVersion = navigator.userAgent.match /Version\/(\d+)/i
if (($.browser.msie and $.browser.version < 9.0) or
    ($.browser.mozilla and $.browser.version < 3.6) or
    ($.browser.opera and $.browser.version < 11.51) or
    ($.browser.safari and chromeVersion and chromeVersion[1] < 13) or
    ($.browser.safari and safariVersion and safariVersion[1] < 5))
  $ ->
    $('#content-fallback').show()
    $('#fallback-ignore').click -> $('#content-fallback').hide()

$.extend REPLIT,
  ISMOBILE: Boolean navigator.userAgent.match /iPhone|iPad|iPod|Android/i
  ISIOS: Boolean navigator.userAgent.match /iPhone|iPad|iPod/i
