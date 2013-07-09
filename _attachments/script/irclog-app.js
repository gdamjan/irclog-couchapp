"use strict";


var irclog = angular.module('ircLog', ['CornerCouch', 'Colorizer']);

irclog.config(function($routeProvider) {
   $routeProvider
      .when('/', {
         templateUrl: 'start.html',
         controller: 'IndexController'
      })
      .when('/:channel', {
         templateUrl: 'channel-logs.html',
         controller: 'ChannelLogsController'
      })
      .otherwise({ redirectTo: '/'});
});

irclog.controller('IndexController', function ($rootScope, $scope, couchdb) {
   delete $rootScope.title;
   $scope.channels = couchdb.getChannels();
});

irclog.controller('ChannelLogsController', function ($rootScope, $scope, $routeParams, cornercouch) {
   $scope.channel = $rootScope.title = $routeParams.channel;

   $scope.db = cornercouch('http://db.softver.org.mk', 'JSONP').getDB('irclog');
   $scope.db.query("log", "channel", {
      include_docs: true,
      descending: true,
      reduce: false,
      limit: 100,
      startkey: [$routeParams.channel, {}],
      endkey: [$routeParams.channel, 0]
   });

   // swaped because of "descending: true" we go back in the past
   $scope.prevClick = function() { $scope.db.queryNext() };
   $scope.nextClick = function() { $scope.db.queryPrev() };

});
