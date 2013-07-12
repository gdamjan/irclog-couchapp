// Copyright: 2013, Jochen Eddelbüttel
// Copyright: 2013, Damjan Georgievski
// MIT License applies
//
'use strict';

angular.module('CouchDB', ['ng']).
factory('couchdb', ['$http', function($http) {

    // Shorthand angular
    var ng = angular;

    function extendJSONP(config) {

        if (config.method === "JSONP")
            if (config.params)
                config.params.callback = "JSON_CALLBACK";
            else
                config.params = { callback: "JSON_CALLBACK" };

        return config;
    }

    function encodeUri(base, part1, part2) {
        var uri = base;
        if (part1) uri = uri + "/" + encodeURIComponent(part1);
        if (part2) uri = uri + "/" + encodeURIComponent(part2);
        return uri.replace('%2F', '/');
    }

    function CouchView(url, qparams, method) {
       // Query cursor
       this.rows = [];
       this.prevRows = [];
       this.nextRow = null;

       var config = {
          method: method || 'GET',
          url:    url
       };

       if (qparams) {
          // Raise limit by 1 for pagination
          if (qparams.limit) qparams.limit++;
          // Convert key parameters to JSON
          for (var p in qparams) switch (p) {
             case "key":
             case "keys":
             case "startkey":
             case "endkey":
                qparams[p] = ng.toJson(qparams[p]);
          }
          config.params = qparams;
       }

       // immutable
       this.qConfig = extendJSONP(config);
    };

    CouchView.prototype.executeQuery = function(qConfig) {
       var self = this;
       return $http(qConfig).success( function (data, dt, hd, config) {

          // Pop extra row for pagination
          if (config.params && config.params.limit) {
             if (data.rows.length == config.params.limit) {
                self.nextRow = data.rows.pop();
             }
             else {
                self.nextRow = null;
             }
          }
          self.rows = data.rows;
          self.update_seq = data.update_seq;
       });
    }

    CouchView.prototype.queryRefresh = function() {
       return this.executeQuery(this.qConfig);
    };

    CouchView.prototype.next = function() {
       var qConfig = ng.copy(this.qConfig);
       var row = this.nextRow;
       if (row) {
          this.prevRows.push(this.rows[0]);
          qConfig.params.startkey = ng.toJson(row.key);
          if (row.id && row.id !== row.key)
             qConfig.params.startkey_docid = row.id;
          return this.executeQuery(qConfig);
       }
       else return null;
    };

    CouchView.prototype.prev = function() {
       var qConfig = ng.copy(this.qConfig);
       var row = this.prevRows.pop();
       if (row) {
          qConfig.params.startkey = ng.toJson(row.key);
          if (row.id && row.id !== row.key)
             qConfig.params.startkey_docid = row.id;
          return this.executeQuery(qConfig);
       }
       else return null;
    };


    // Database-level constructor
    // Database name is required parameter
    function CouchDB(dbName, serverUri, getMethod) {

        // Basic fields
        this.uri  = encodeUri(serverUri, dbName);
        this.method = getMethod;

    }

    CouchDB.prototype.getInfo = function () {

        var db = this;
        return $http ({
            method:     "GET",
            url:        this.uri + "/"
        })
        .success(function(data) {
            db.info = data;
        });
    };

    CouchDB.prototype.newDoc = function(initData) {

        return new this.docClass(initData);

    };

    CouchDB.prototype.getDoc = function(id) {

        var doc = new this.docClass();
        doc.load(id);
        return doc;

    };

    CouchDB.prototype.getQueryDoc = function(idx) {

        var row = this.rows[idx];

        if (!row.doc) return this.getDoc(row.id);

        var doc = row.doc;

        if (doc instanceof this.docClass) return doc;

        doc = this.newDoc(doc);
        row.doc = doc;
        return doc;
    };

    CouchDB.prototype.query = function(design, view, qparams)
    {
        return new CouchView(
            "/_design/" + encodeURIComponent(design) +
            "/_view/"   + encodeURIComponent(view),
            qparams
        );
    };

    CouchDB.prototype.list = function(design, list, view, qparams)
    {
        return new CouchView(
            "/_design/" + encodeURIComponent(design) +
            "/_list/" + encodeURIComponent(list) +
            "/" + encodeURIComponent(view),
            qparams
        );
    };

    CouchDB.prototype.queryAll = function(qparams)
    {
        return new CouchView("/_all_docs", qparams);
    };

    function CouchServer(url, getMethod) {
        if (url) {
            this.uri = url;
            this.method = getMethod || "JSONP";
        }
        else {
            this.uri = "";
            this.method = "GET";
        }
    }

    CouchServer.prototype.getDB = function(dbName) {
        return new CouchDB(dbName, this.uri, this.method);
    };

    CouchServer.prototype.getUserDB = function() {
        if (!this.userDB) this.userDB = this.getDB("_users");
        return this.userDB;
    };

    CouchServer.prototype.getUserDoc = function () {
        var db = this.getUserDB();
        if (this.userCtx.name)
            this.userDoc = db.getDoc("org.couchdb.user:" + this.userCtx.name);
        else
            this.userDoc = db.newDoc();
        return this.userDoc;
    };

    CouchServer.prototype.getInfo = function () {

        var server = this;
        return $http ({
            method:     "GET",
            url:        this.uri + "/"
        })
        .success(function(data) {
            server.info = data;
        });
    };

    CouchServer.prototype.getDatabases = function () {

        var server = this;
        return $http ({
            method:     "GET",
            url:        this.uri + "/_all_dbs"
        })
        .success(function(data) {
            server.databases = data;
        });
    };

    CouchServer.prototype.createDB = function(dbName) {
        var server = this;
        return $http ({
            method:     "PUT",
            url:        encodeUri(server.uri, dbName)
        })
        .success(function () {
            if (server.databases) server.databases.push(dbName);
        });
    };

    CouchServer.prototype.session = function() {

        var server = this;
        return $http ({
            method:     "GET",
            url:        this.uri + "/_session"
        })
        .success(function(data) {
            server.userCtx = data.userCtx;
        });
    };

    CouchServer.prototype.login = function(usr, pwd) {

        var body =
            "name="      + encodeURIComponent(usr) +
            "&password=" + encodeURIComponent(pwd);

        var server = this;
        var userName = usr;
        return $http({
            method:     "POST",
            url:        this.uri + "/_session",
            headers:    { "Content-Type":
                          "application/x-www-form-urlencoded" },
            data:       body.replace(/%20/g, "+")
        })
        .success(function(data) {
            delete data["ok"];
            server.userCtx = data;
            // name is null in POST response for admins as of Version 1.2.1
            // This patches over the problem
            server.userCtx.name = userName;
        });

    };

    CouchServer.prototype.logout = function() {

        var server = this;
        return $http ({
            method:     "DELETE",
            url:        this.uri + "/_session"
        })
        .success(function() {
            server.userCtx = { name: null, roles: [] };
            server.userDoc = { };
        });
    };

    CouchServer.prototype.getUUIDs = function(cnt) {

        var server = this;
        return $http ({
            method:     "GET",
            url:        this.uri + "/_uuids",
            params:     { count: cnt || 1 }
        })
        .success(function(data) {
            server.uuids = data.uuids;
        });
    };


    return {
       Server:    function (url, method) { return new CouchServer(url, method) },
       Database:  function (url, method) { return new CouchDB(url, method) },
       View:      function (url, params, method) { return new CouchView(url, params, method) }
    };

}]);
