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
   $scope.rows = [];

   var view = couchView(URL_BASE + 'ddoc/_view/channel', {
      include_docs: true,
      descending: true,
      limit: 100,
      startkey: [$routeParams.channel, {}],
      endkey: [$routeParams.channel, 0]
   });

   view.get().then(function (result) {
      $scope.rows.push.apply($scope.rows, result.rows)

      var params = { include_docs:true, since: result.last_seq,
                     filter: 'log/channel', channel: 'lugola' };

      couchChanges(URL_BASE + 'api/_changes', params).then(
         null,
         function (err) { console.log(err) },
         function (data) {
            console.log("notify");
            $scope.rows.push.apply($scope.rows, data.results);
         }
      );

   });

   var pager = view;
   $scope.prevClick = function() {
      // .next() because of "descending: true" we go back towards the past
      pager = pager.next();
      pager.get().then(function (result) {
         $scope.rows.concat(result.rows);
      })
   };
})
