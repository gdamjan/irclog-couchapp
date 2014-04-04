// Copyright: 2014, Damjan Georgievski
// MIT License applies
//
'use strict';

angular.module('CouchDB')
.factory('couchView', function($http) {

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
         if (qparams.limit) { qparams.limit++ };
         // Convert key parameters to JSON
         for (var p in qparams) switch (p) {
            case "key":
            case "keys":
            case "startkey":
            case "endkey":
               qparams[p] = angular.toJson(qparams[p]);
         }
         config.params = qparams;
      }

      this.qConfig = angular.copy(config);
   };

   CouchView.prototype.executeQuery = function(qConfig) {
      var self = this;
      return $http(qConfig).then( function (result) {

         // Pop extra row for pagination
         if (result.config.params && result.config.params.limit) {
            if (result.data.rows.length == result.config.params.limit) {
               self.nextRow = result.data.rows.pop();
            }
            else {
               self.nextRow = null;
            }
         }
         self.rows = result.data.rows;
         self.update_seq = result.data.update_seq;
      });
   }

   CouchView.prototype.queryRefresh = function() {
      return this.executeQuery(this.qConfig);
   };

   CouchView.prototype.next = function() {
      var qConfig = angular.copy(this.qConfig);
      var row = this.nextRow;
      if (row) {
         this.prevRows.push(this.rows[0]);
         qConfig.params.startkey = angular.toJson(row.key);
         if (row.id && row.id !== row.key)
            qConfig.params.startkey_docid = row.id;
         return this.executeQuery(qConfig);
      }
      else return null;
   };

   CouchView.prototype.prev = function() {
      var qConfig = angular.copy(this.qConfig);
      var row = this.prevRows.pop();
      if (row) {
         qConfig.params.startkey = angular.toJson(row.key);
         if (row.id && row.id !== row.key)
            qConfig.params.startkey_docid = row.id;
         return this.executeQuery(qConfig);
      }
      else return null;
   };

   return function (url, params, method) { return new CouchView(url, params, method) }
})
