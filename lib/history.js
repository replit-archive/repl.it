/**
 * @fileoverview A plugin for efficient navigation using the HTML5 history API
 * with hash fallbacks for older browsers. Based on MIT-licensed work by Ben
 * Cherry (bcherry@gmail.com).
 */
(function($) {
  // Is the HTML5 history API supported?
  var historySupported = Boolean(window.history && history.pushState);
  // Is the HTML5 hashchange event supported?
  var hashchangeSupported = (function() {
    var isSupported = "onhashchange" in window;
    if (!isSupported && window.setAttribute) {
      window.setAttribute("onhashchange", "return;");
      isSupported = typeof window.onhashchange === "function";
    }
    return isSupported;
  })();

  // Returns the state currently in the hash. Removes the bang prefix if needed.
  var getHashState = function() {
    return location.hash.replace(/^#!?/, '');
  };
  // The last state (hash or path).
  var lastState = null;

  $.nav = function(handler) {
    // Determine what state we should be in initially.
    if (location.hash && location.hash.length > 1) {
      lastState = getHashState();
    } else {
      // NOTE: IE does not have a leading slash for pathname.
      lastState = location.pathname.replace(/^\//, '');
    }
    // If the initial state and path don't match, update it and send an event.
    if (lastState != location.pathname.replace(/^\//, '')) {
      if (historySupported) {
        var path = (location.protocol + "//" +
                    location.hostname +
                    (location.port ? ":" + location.port : "") +
                    '/' + lastState);
      }
      handler(lastState, null);
    }

    // Set up event listeners.
    if (hashchangeSupported) {
    
      // Use the hashchange API.
      $(window).bind('hashchange', function() {
        handler(lastState = getHashState(), null);
      });
    } else if (historySupported) {
      // Use the history API.
      $(window).bind("popstate", function() {
        // Handle the new state.
        var target = getHashState();
         console.log(target, lastState);
        if (lastState != target) {
          handler(lastState = target, null);
        }
      });
    } else {
      // Emulate hashchange if not supported.
      setInterval(function() {
        if (lastState !== getHashState()) {
          handler(lastState = getHashState(), null);
        }
      }, 250);
    }
  };

  $.nav.getState = function() {
    return lastState;
  };
  $.nav.pushState = function (path) {
    var a = $('<a/>', {href:path})[0];
    location.hash = '!' + a.pathname.replace(/^\//, '');
  }
}(jQuery));