// Copyright: 2014, Damjan Georgievski
// MIT License applies
//
'use strict';

angular.module('gdamjan.CouchDB')
.factory('couchView', function($http, $q) {

   function CouchView(url, params, method) {
      this.method = method || 'GET';
      this.url    = url;
      this.params = params;
      this._loaded = $q.defer();
   }

   CouchView.prototype.get = function() {
      var self = this;
      return $q.when(self.params).then(function (params) {
         var req = getView(self.method, self.url, params);
         return $q.all({req: req, params: params});
      }).then(function(all) {
         // prepare params for loadAfter and loadBefore
         var nextparams, prevparams;
         if (all.req.config.params && all.req.config.params.limit) {
            if (all.req.data.rows.length == all.req.config.params.limit) {
               // pop the extra last row for pagination
               var last = all.req.data.rows.pop();
               nextparams = angular.copy(all.params);
               nextparams.startkey = last.key;
               nextparams.startkey_docid = last.id;
            }
         }
         if (all.req.data.rows.length > 0) {
            var first = all.req.data.rows[0];
            prevparams = angular.copy(all.params);
            prevparams.endkey = first.key;
            prevparams.endkey_docid = first.id;
         }
         self._loaded.resolve({nextparams:nextparams, prevparams:prevparams});
         return {rows: all.req.data.rows, last_seq: all.req.data.update_seq };
      });
   };

   CouchView.prototype.loadAfter = function() {
      var next = new CouchView(this.url, null, this.method);
      next.params = this._loaded.promise.then(function (obj) { return obj.nextparams});
      return next;
   };

   CouchView.prototype.loadBefore = function() {
      var prev = new CouchView(this.url, null, this.method);
      prev.params = this._loaded.promise.then(function (obj) { return obj.prevparams});
      return prev;
   };

   function getView (method, url, _params) {

      var params = { reduce: false, update_seq: true};
      angular.extend(params, _params);

      // Raise limit by 1 for pagination
      if (params.limit) { params.limit++; }
      // Convert key parameters to JSON
      for (var p in params) switch (p) {
         case "key":
         case "keys":
         case "startkey":
         case "endkey":
            params[p] = angular.toJson(params[p]);
      }

      return $http({method: method, url: url, params: params});
   }

   return function (url, params, method) { return new CouchView(url, params, method); };
})
