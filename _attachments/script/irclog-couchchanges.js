"use strict";
/* A module for the CouchDB changes feed
 * 
 * it will use either EventSource or longpoll depending on what's available in the browser or on the server (todo)
 * it provides a unified api through a promise that notifies.
 */

angular.module('CouchDB')
.factory('couchchanges', function($http, $q, $timeout) {
  
   function realEventSource(url, params) {
      var _params = { heartbeat: 10000, feed: 'eventsource'};
      var _url = buildUrl(url, _params);
      var source = new EventSource(_url);
      var result = $q.defer();

      source.addEventListener('message', function(ev) {
         var data = JSON.parse(ev.data);
         result.notify(data);
      }, false);

      source.addEventListener('open', function() {
         console.log("Connection was opened.");
      }, false);

      source.addEventListener('error', function(err) {
         if (err.readyState == EventSource.CLOSED) {
            console.log("Connection was closed.");
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
      
      function _loop () {
         var _params = { heartbeat: 20000, feed: 'longpoll'};
         angular.extend(_params, params);

         var req = $http({method: 'GET', url: url, params: _params, timeout: DEADLINE});

         req.then(function(response) {
            result.notify(response.data);
            $timeout(_loop, 1); // poor mans TCO
         }).catch(function(err) {
            if (err.status == 0) { // timeout
               $timeout(_loop, 15000); // poor mans TCO
            } else {
	       // either restart the _loop or reject the promise
               // result.reject(err);
	       // but lets just debug for now until I see all the breakages that can happen
               console.log(err); // DEBUG
            }
         });
      }
      $timeout(_loop, 1); // start it the first time
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
