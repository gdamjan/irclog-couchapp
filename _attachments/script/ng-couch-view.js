// Copyright: 2014, Damjan Georgievski
// MIT License applies
//
'use strict';

angular.module('CouchDB')
.factory('couchView', function($http, $q) {

   function CouchView(url, params, method) {
      this.method = method || 'GET';
      this.url    = url;
      this.params = params;
      this.nextparams = $q.defer();
      this.prevparams = $q.defer();
   };

   CouchView.prototype.get = function() {
      var self = this;
      return $q.when(self.params).then(function (params) {
         return getView(self.method, self.url, params).then(function(result) {
            // prepare params for loadAfter and loadBefore
            var nextparams = angular.copy(params);
            var prevparams = angular.copy(params);
            if (result.config.params && result.config.params.limit) {
               if (result.data.rows.length == result.config.params.limit) {
                  // pop the extra last row for pagination
                  var last = result.data.rows.pop();
                  nextparams.startkey = last.key;
                  nextparams.startkey_docid = last.id;
               }
            }
            if (result.data.rows.length > 0) {
               var first = result.data.rows[0];
               prevparams.endkey = first.key;
               prevparams.endkey_docid = first.id;
            }
            self.nextparams.resolve(nextparams);
            self.prevparams.resolve(prevparams);
            return {rows: result.data.rows, last_seq: result.data.update_seq }
         });
      });
   }

   CouchView.prototype.loadAfter = function() {
      var next = new CouchView(this.url, null, this.method);
      next.params = this.nextparams.promise;
      return next;
   };

   CouchView.prototype.loadBefore = function() {
      var prev = new CouchView(this.url, null, this.method);
      prev.params = this.prevparams.promise;
      return prev;
   };

   function getView (method, url, _params) {

      var params = { reduce: false, update_seq: true};
      angular.extend(params, _params);

      // Raise limit by 1 for pagination
      if (params.limit) { params.limit++ };
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

   return function (url, params, method) { return new CouchView(url, params, method) }
})
