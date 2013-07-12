"use strict";


angular.module('ircLog', ['ngRoute', 'CouchDB', 'Colorizer'], function($routeProvider) {
   $routeProvider
      .when('/', {
         templateUrl: 'start.html',
         controller: 'StartController'
      })
      .when('/:channel', {
         templateUrl: 'channel-log.html',
         controller: 'ChannelLogsController'
      })
      .otherwise({ redirectTo: '/'});
})

.controller('StartController', function ($rootScope, $scope, couchdb) {
   delete $rootScope.title;
   $scope.cursor = couchdb.View('ddoc/_view/channel', {
      reduce: true,
      group_level: 1
   });
})

.controller('ChannelLogsController', function ($rootScope, $scope, $routeParams, couchdb) {
   $scope.channel = $rootScope.title = $routeParams.channel;

   $scope.cursor = couchdb.View('ddoc/_view/channel', {
      include_docs: true,
      descending: true,
      reduce: false,
      limit: 100,
      startkey: [$routeParams.channel, {}],
      endkey: [$routeParams.channel, 0]
   });

   // swaped because of "descending: true" we go back in the past
   $scope.prevClick = function() { $scope.cursor.next() };
   $scope.nextClick = function() { $scope.cursor.prev() };

})
