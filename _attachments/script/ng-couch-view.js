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
      this._startkey = params.startkey;
      this._endkey   = params.endkey;
      this._firstKey = $q.defer();
      this._lastKey  = $q.defer();
   };

   CouchView.prototype.get = function() {
      var self = this;
      return $q.all([self._startkey, self._endkey]).then(function (keys) {
         var params = angular.copy(self.params)
         params.startkey = keys[0];
         params.endkey   = keys[1];
         return getView(self.method, self.url, params).then(function(result) {
            // pop the extra last row for pagination
            if (result.config.params && result.config.params.limit) {
               if (result.data.rows.length == result.config.params.limit) {
                  self._lastKey.resolve(result.data.rows.pop().id);
               }
            }
            if (result.data.rows.length > 0) {
               self._firstKey.resolve(result.data.rows[0].id);
            }
            return {rows: result.data.rows, last_seq: result.data.update_seq }
         });
      });
   }

   CouchView.prototype.loadAfter = function() {
      var next = new CouchView(this.url, this.params, this.method);
      next._startkey = this._lastKey;
      next._endkey   = this._endkey;
      return next;
   };

   CouchView.prototype.loadBefore = function() {

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
