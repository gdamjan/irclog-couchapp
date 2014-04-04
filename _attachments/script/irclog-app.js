"use strict";

var URL_BASE = 'https://irc.softver.org.mk/';

angular.module('ircLog', ['ngRoute', 'CouchDB', 'Colorizer'], function($routeProvider) {
   $routeProvider
      .when('/', {
         templateUrl: 'home.html',
         controller: 'HomeController'
      })
      .when('/:channel', {
         templateUrl: 'channel-log.html',
         controller: 'ChannelLogsController'
      })
      .otherwise({ redirectTo: '/'});
})

.controller('HomeController', function ($rootScope, $scope, couchView) {
   delete $rootScope.title;
   $scope.cursor = couchView(URL_BASE + 'ddoc/_view/channel', {
      reduce: true,
      group_level: 1
   });
   $scope.cursor.queryRefresh();
})

.controller('ChannelLogsController', function ($rootScope, $scope, $routeParams,
                                               couchView, couchChanges) {
   $scope.channel = $rootScope.title = $routeParams.channel;

   $scope.cursor = couchView(URL_BASE + 'ddoc/_view/channel', {
      include_docs: true,
      descending: true,
      reduce: false,
      update_seq: true,
      limit: 100,
      startkey: [$routeParams.channel, {}],
      endkey: [$routeParams.channel, 0]
   });

   // swaped because of "descending: true" we go back in the past
   $scope.prevClick = function() { $scope.cursor.next() };
   $scope.nextClick = function() { $scope.cursor.prev() };

   $scope.cursor.queryRefresh().then(function() {

      var params = { include_docs:true, since: $scope.cursor.update_seq,
                     filter: 'log/channel', channel: 'lugola' };
      var ch = couchChanges(URL_BASE + 'api/_changes', params);
      ch.then(
         function (s) { console.log(s) },
         function (err) { console.log(err) },
         function (data) { console.log(data) }
      );
   });
})
