/*
 * A simple stateless read-only api for CouchApps
 *
 * this api will only work with the specific rewrites as in
 * https://github.com/gdamjan/irclog-couchapp/blob/master/rewrites.json
 * it does not need any setup, and will work no matter if you serve the app
 * from a couchdb vhost, or from the design doc directly. it doesn't care what
 * your database is named either, or if it's proxied behind a path.
 *
 * Depends on jQuery and JSON.stringify
 */

var $Couch = function ($) {

    var common_options = {
        cache: false,
        async: true,
        dataType: 'json',
        contentType: 'application/json'
    }

    var get = function (id, opts) {
        var _opts = $.extend({}, opts, common_options);
        return $.ajax("api/" + id, _opts);
    }

    var create = function (doc, id, opts) {
        var _opts = $.extend({}, opts, common_options);
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
        var _opts = $.extend({}, opts, common_options);
        var _query = {
           update_seq: true,
           stale: "update_after",
           reduce: false
        }

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
        var _opts = $.extend({}, opts, common_options);
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
