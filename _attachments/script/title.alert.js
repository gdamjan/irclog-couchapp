var $TitleAlert = (function(document, window, undefined) {
  var options = {
      count: 2,        // by default flash 2 times
      period: 1200,    // default period 1200ms
      flashTitle: " --- ** --- "
  }

  // private
  var origTitle = document.title;
  var intervalID = undefined;
  var halfperiods = 0;

  var runner = function () {
    if (halfperiods % 2 == 0) {
      document.title = options.flashTitle;
    } else {
      document.title = origTitle;
    }
    halfperiods--;
    if (0 >= halfperiods) {
      stop();
    }
  }

  // public api
  var start = function () {
    if (intervalID !== undefined) {
      // already started, do 1 more flash.
      // but don't start the Interval again
      halfperiods += 2;
      return;
    }
    origTitle = document.title;      // remember the original title
    halfperiods = 2 * options.count; // initialize the counter
    runner();                        // immediately make a run

    // finally setup an interval to run the callback on each half of the period
    intervalID = window.setInterval(runner, options.period / 2);
  }

  var stop = function () {
    if (intervalID !== undefined) {
      window.clearInterval(intervalID);
      intervalID = undefined;
    }
    document.title = origTitle;
  }

  return { start: start, stop: stop, options: options};
})(document, window);