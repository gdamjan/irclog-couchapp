// Copyright: 2014, Damjan Georgievski
// MIT License applies
//
'use strict';

angular.module('gdamjan.CouchDB')
.factory('couchDB', function($http) {

   function CouchDB(url) {
      // normalize url
      // replace zero or more trailing slashes with a single one
      this.url  = url.replace(/\/*$/, '/');
   }

   CouchDB.prototype.getInfo = function () {
      var db = this;
      return $http ({
         method:  "GET",
         url:     this.url
      }).then(function(result) {
         db.info = result.data;
      });
   };

   CouchDB.prototype.getDoc = function(id) {
      return $http ({
         method: "GET",
         url: this.url + id
      }).then(function(result) {
         return result.data;
      });
   };

   return function (url) { return new CouchDB(url) }
})
