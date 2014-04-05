/* Copyright: 2014, Damjan Georgievski
 * MIT License applies
 *
 * A module for the CouchDB changes feed
 *
 * it will use either EventSource or longpoll depending on what's available in the browser or on the server (todo)
 * it provides a unified api through a promise that notifies.
 */
"use strict";

angular.module('CouchDB')
.factory('couchChanges', function($http, $q, $timeout) {

   function realEventSource(url, params) {
      var _params = { heartbeat: 10000, feed: 'eventsource'};
      var _url = buildUrl(url, _params);
      var source = new window.EventSource(_url);
      var result = $q.defer();

      source.addEventListener('message', function(ev) {
         var data = angular.fromJson(ev.data);
         result.notify(data);
      }, false);

      source.addEventListener('open', function() {
         console.log("EventSource connection was opened.");
      }, false);

      source.addEventListener('error', function(err) {
         if (err.readyState == EventSource.CLOSED) {
            console.log("EventSource connection was closed.");
         } else {
            console.log("error", err);
         }
      }, false);

      result.promise.close = function() {
         source.close();
      }
      return result.promise;
   }

   // a longpoll request can get stuck at the TCP level
   // so kill it each 60 seconds and retry it just in case
   var DEADLINE = 60000;

   function longPolledEventSource (url, params) {
      var result = $q.defer();
      // return error if no since ?
      var _params = { heartbeat: 20000, feed: 'longpoll'};
      angular.extend(_params, params);

      function _loop (last_seq) {
         _params.since = last_seq;
         var req = $http({method: 'GET', url: url, params: _params, timeout: DEADLINE});

         req.then(function(response) {
            result.notify(response.data);
            _loop(response.data.last_seq);
         });
         req.catch(function(err) {
            if (err.status == 0) {
               // 0 is timeout, repeat
               _loop(last_seq);
            } else {
               // either restart the _loop or reject the promise
               // but lets just debug for now until I see all the breakages that can happen
               result.reject(err);
            }
         });
      }
      _loop(params.since); // start it the first time
      return result.promise;
   }

   // I'm testing longPolledEventSource for now
   return longPolledEventSource;


   if (!!window.EventSource) {
      return realEventSource;
   } else {
      return longPolledEventSource;
   }
})
