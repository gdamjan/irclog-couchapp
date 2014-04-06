/* Copyright: 2014, Damjan Georgievski
 * MIT License applies
 *
 * A module for the CouchDB changes feed
 *
 * it will use either EventSource or longpoll depending on what's available in the browser or on the server (todo)
 * it provides a unified api through a promise that notifies.
 */
"use strict";

angular.module('gdamjan.CouchDB')
.factory('couchChanges', function($http, $q, $timeout) {

   function buildUrl(url, params) {
     var str = [];
     for(var p in params)
       if (params.hasOwnProperty(p)) {
         str.push(encodeURIComponent(p) + "=" + encodeURIComponent(params[p]));
       }
     return url + '?' + str.join("&");
   }

   // a longpoll request can get stuck at the TCP level
   // so kill it each 60 seconds and retry it just in case
   var DEADLINE = 60000;
   var HEARTBEAT = 20000;
   function longPollFallback (url, params, result) {
      var _params = angular.copy(params);
      _params.feed = 'longpoll';
      _params.heartbeat = HEARTBEAT;

      function _loop (last_seq) {
         _params.since = last_seq;
         var req = $http({method: 'GET', url: url, params: _params, timeout: DEADLINE});

         req.then(function(response) {
            result.notify(response.data.results);
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
   }


   return function (url, params) {
      var result = $q.defer();
      // return error if no since ?

      if (!!window.EventSource) {
         var _params = angular.copy(params);
         _params.feed = 'eventsource';
         _params.heartbeat = HEARTBEAT;
         var _url = buildUrl(url, _params);
         var do_fallback = true;
         var source = new window.EventSource(_url);

         source.addEventListener('error', function() {
            // don't do the fallback if we succeed, Firefox was firing a lingering
            // longpoll fallback on a page reload
            do_fallback = false;
         });
         source.addEventListener('error', function(err) {
            if (source.readyState == window.EventSource.CLOSED &&
                           err.type == 'error' && err.eventPhase == 2) {
               if (do_fallback) {
                  // EventSource not supported on the backend, run the longpolled fallback
                  console.log('EventSource not supported on the backend? runing longpoll');
                  longPollFallback(url, params, result);
               }
            } else if (source.readyState == window.EventSource.CLOSED) {
               result.reject(err);
            }
         }, false);

         source.addEventListener('message', function(ev) {
            var data = angular.fromJson(ev.data);
            result.notify([data]);
         }, false);
      } else {
         // no window.EventSource
         longPollFallback(url, params, result);
      }

      return result.promise;
   }
})
