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
        var _opts = $.extend({}, global_settings, opts);
        if (id === undefined) {
            id = "api/";
            _opts.type = 'POST';
        } else {
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

    // creates a `changes` object whis has 4 methods:
    //   start()
    //   stop()
    //   on_change(callback)
    //   on_error(callback)
    var changes = function (last_seq, query, opts) {
        var start_opts = $.extend({}, global_settings, opts);
        var _query = {
           feed: "longpoll",
           heartbeat: 30000,
        }
        start_opts.data = $.extend({}, _query, query);

        var closure = jQuery({});
        closure._stopped = true;
        closure._last_seq = last_seq;
        closure._jqXHR = null;

        function changes_loop(_last_seq, _options) {
           _options.data.since = _last_seq;
           var jqXHR = $.ajax("api/_changes", _options);
           closure._jqXHR = jqXHR;

           jqXHR.done(function (data) {
              closure.trigger("on_change", [data]);
              closure._last_seq = data.last_seq;
              if (closure._stopped !== true) {
                 window.setTimeout(changes_loop, 0, data.last_seq, _options);
              }
           })

           jqXHR.fail(function (ev) {
              // restart on error (maybe even do a real backoff?)
              closure.trigger("on_error", [ev]);
              if (closure._stopped !== true) {
                 window.setTimeout(changes_loop, 1000, _options);
              }
           })
        }

        var emiter = {};
        emiter.start = function() {
           if (closure._stopped) {
              closure._stopped = false;
              changes_loop(closure._last_seq, start_opts);
           }
        }
        emiter.stop = function() {
           closure._stopped = true;
           if (closure._jqXHR) {
              closure._jqXHR.abort();
           }
        };
        emiter.on_change = function(callback) {
           closure.bind("on_change", function (ev, data) {callback(data)})
        }
        emiter.on_error = function(callback) {
           closure.bind("on_error", function (ev, error) {callback(error)})
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
