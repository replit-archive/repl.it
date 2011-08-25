(function ($) {
  // Is the HTML5 history API supported?
  var historySupported = Boolean(window.history && history.pushState);

  // Is the HTML5 hashchange event supported?
  var hashchangeSupported = (function() {
    var isSupported = 'onhashchange' in window;
    if (!isSupported && window.setAttribute) {
      window.setAttribute('onhashchange', 'return;');
      isSupported = typeof window.onhashchange === 'function';
    }
    return isSupported;
  })();

  var getPath = function () {
    return window.location.hash.replace(/^#/, '');
  };

  $.hashchange = function (callback) {
    if (historySupported) {
      $(window).bind('popstate', function () {
        callback(getPath());
      });
    } else if (hashchangeSupported) {
      $(window).bind('hashchange', function () {
        callback(getPath());
      });
      // Emulate first hashchange.
      if (getPath()) $(window).trigger('hashchange');
    } else {
      var lastState = '';
      setInterval(function() {
        if (lastState !== getPath()) callback(lastState = getPath());
      }, 250);
    }
    return this;
  };
})(jQuery);
