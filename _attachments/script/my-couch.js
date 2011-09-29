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
        var _opts = $.extend({}, opts, global_settings);
        return $.ajax("api/" + id, _opts);
    }

    var create = function (doc, id, opts) {
        var _opts = $.extend({}, opts, global_settings);
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
        var _opts = $.extend({}, opts, global_settings);
        var _query = {
           update_seq: true,
           stale: "update_after",
           reduce: false
        }

        // stringify if needed
        function assure_string(obj, attr) {
            if (obj[attr] && typeof obj[attr] !== "string")
                obj[attr] = JSON.stringify(obj[attr]);
        }
        assure_string(query, "key");
        assure_string(query, "startkey");
        assure_string(query, "endkey");

        _opts.data = $.extend({}, query, _query);
        return $.ajax("ddoc/_view/" + id, _opts);
    }

    var changes = function (since, query, callback, opts) {
        var _opts = $.extend({}, opts, global_settings);
        var _query = {
           feed: "longpoll",
           heartbeat: 10000
        }
        _opts.data = $.extend({}, query, _query);

        function fireaway (since, callback, opts) {
           opts.data.since = since;
           $.when( $.ajax("api/_changes", opts) ).then(
              function (data) {
                  callback(data);
                  window.setTimeout(fireaway, 0, data.last_seq, callback, opts);
              },
              function (data) {
                  // restart on error (maybe real backoff?)
                  window.setTimeout(fireaway, 1000, since, callback, opts);
              }
           )
        }
        fireaway (since, callback, _opts);
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
