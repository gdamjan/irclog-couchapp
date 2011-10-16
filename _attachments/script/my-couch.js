/*
 *
 * A simple stateless api for CouchApps
 *
 * This api will only work with the specific rewrites (see bottom of this file)
 * It does not require any setup, and will work no matter if you serve the app
 * from a couchdb vhost, or from the design doc rewriter. It doesn't care what
 * your database is named either, or if it's proxied behind a path.
 *
 * Depends on jQuery>1.5 and JSON.stringify
 *
 * The api is a singleton object, a thin wrapper around jQuery $.ajax()
 *
 * All methods return the jQuery jqXHR object which, since 1.5 implements the
 * Promise interface, so you specify your callbacks using the done/fail and when/then
 * methods of jQuery.
 * see:
 *   http://api.jquery.com/jQuery.ajax/#jqXHR
 *   http://api.jquery.com/category/deferred-object/
 *
 */

var $Couch = function ($) {

    var global_settings = {
        cache: false,
        async: true,
        dataType: 'json',
        contentType: 'application/json'
    }

    var get = function (id, opts) {
        var _opts = $.extend({}, global_settings, opts);
        return $.ajax("api/" + id, _opts);
    }

    var create = function (doc, id, opts) {
        var _opts = $.extend({type:'POST'}, global_settings, opts);
        // if id is undefined, default is POST to the database
        // otherwise if the id doesn't have a slash it's a PUT to the ./api/<id>
        // otherwise it's a POST to the id directly (usefull for update functions)
        if (id === undefined) {
            id = "api/";
        } else if (id.indexOf('/') === -1) {
            id = "api/" + id;
            _opts.type = 'PUT';
        }
        // stringify if needed
        if (typeof doc !== 'string') {
            doc = JSON.stringify(doc);
        }
        _opts.data = doc;
        return $.ajax(id, _opts)
    }

    var view = function (id, query, opts) {
        var _opts = $.extend({}, global_settings, opts);
        var _query = {
           update_seq: true,
           reduce: false
        }

        // stringify if needed
        function assure_string(obj, attr) {
            if (obj && obj[attr] && typeof obj[attr] !== "string")
                obj[attr] = JSON.stringify(obj[attr]);
        }
        assure_string(query, "key");
        assure_string(query, "startkey");
        assure_string(query, "endkey");

        _opts.data = $.extend({}, _query, query);
        return $.ajax("ddoc/_view/" + id, _opts);
    }

    /*
     * creates a `changes` object whis has 4 methods:
     *   start()
     *   stop()
     *   on_change(callback)
     *   on_error(callback)
     *
     * it'll stay subscribed to the _changes feed forever, and reconnect
     * on errors (using an exponentional backoff). also a watchdog is started
     * that will make sure the TCP/IP connection didn't get stuck.
     */
    var changes = function (last_seq, query, opts) {
        var start_opts = $.extend({}, global_settings, opts);
        var _query = {
           feed: "longpoll",
           heartbeat: 30000
        }
        start_opts.data = $.extend({}, _query, query);

        var state = {};
        state.event = jQuery({});
        state.stopped = true;
        state.last_seq = last_seq;
        state.jqXHR = null;
        state.fail_count = 0;
        state.watchdogID = null;

        function watchdog(interval) {
           var w = $.ajax("api/", {timeout: 5000})
           w.done(function (msg, textStatus) {
              state.watchdogID = window.setTimeout(watchdog, interval, interval)
           });
           w.fail(function (_, textStatus) {
              console.log("Watchdog failed with: ", textStatus);
              if (state.watchdogID !== null)
                 window.clearTimeout(state.watchdogID);
              state.watchdogID = null;
              state.jqXHR.abort();
           });
        }

        function changes_loop(_last_seq, _options) {
           _options.data.since = _last_seq;
           var jqXHR = $.ajax("api/_changes", _options);
           state.jqXHR = jqXHR;

           jqXHR.done(function (data) {
              state.event.trigger("on_change", [data]);
              state.last_seq = data.last_seq;
              state.fail_count = 0;
              if (state.watchdogID !== null)
                 window.clearTimeout(state.watchdogID);
              state.watchdogID = null;
              if (state.stopped !== true) {
                 window.setTimeout(changes_loop, 50, data.last_seq, _options);
              }
           })

           jqXHR.fail(function (_, textStatus, errorThrown) {
              // restart on error, binary exponential truncated backoff
              state.event.trigger("on_error", [textStatus, errorThrown]);
              if (state.stopped !== true) {
                 state.fail_count<5 ? state.fail_count++ : state.fail_count;
                 var backoff = (2<<state.fail_count) * 1500;
                 window.setTimeout(changes_loop, backoff, _last_seq, _options);
              }
           })

           watchdog(_options.data.heartbeat * 2);
           return jqXHR;
        }

        var emiter = {};
        emiter.start = function() {
           if (state.stopped) {
              state.stopped = false;
              return changes_loop(state.last_seq, start_opts);
           }
           return state.jqXHR;
        }
        emiter.stop = function() {
           state.stopped = true;
           if (state.jqXHR) {
              state.jqXHR.abort();
           }
        };
        emiter.on_change = function(callback) {
           state.event.bind("on_change", function (_ev, data) {
              callback(data)
           })
        }
        emiter.on_error = function(callback) {
           state.event.bind("on_error", function (_ev, textStatus, errorThrown) {
              callback(textStatus, errorThrown)
           })
        }

        return emiter;
    }


    return { get: get, create: create, view: view, changes: changes }

}(jQuery);

/*
 * rewrites.json
[
 {"from": "/",         "to": "index.html"},
 {"from": "/script",   "to": "/script"},
 {"from": "/script/*", "to": "/script/*"},
 {"from": "/style",    "to": "/style"},
 {"from": "/style/*",  "to": "/style/*"},
 {"from": "/images",   "to": "/images"},
 {"from": "/images/*", "to": "/images/*"},
 {"from": "/api",      "to": "../../"},
 {"from": "/api/*",    "to": "../../*"},
 {"from": "/ddoc",     "to": "./"},
 {"from": "/ddoc/*",   "to": "./*"},
 {"from": "/*",        "to": "*"}
]

 * snippet for index.html

  <script type="text/javascript">
     if (/\/_rewrite$/.test(window.location.pathname))
        // redirect _rewrite to _rewrite/
        // to  normalize access to relative urls through the rewriter
        window.location.pathname = window.location.pathname + "/";
  </script>

*/

/*
Copyright (C) 2011 by Damjan Georgievski <gdamjan@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
