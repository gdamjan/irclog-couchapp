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
      .when('/:channel/by-id/:docid', {
         templateUrl: 'channel-log.html',
         controller: 'ChannelLogAroundDocController'
      })
      .otherwise({ redirectTo: '/'});
})

.controller('HomeController', function ($rootScope, $scope, couchView) {
   delete $rootScope.title;
   $scope.rows = [];
   couchView(URL_BASE + 'ddoc/_view/channel', {
      reduce: true,
      group_level: 1
   }).get().then(function(result) {
      $scope.rows.push.apply($scope.rows, result.rows)
   });
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
      // because of "descending: true" we go back towards the past,
      // so counterintuitively use .loadAfter()
      pager = pager.loadAfter();
      pager.get().then(function (result) {
         $scope.rows.push.apply($scope.rows, result.rows);
      })
   };
})

.controller('ChannelLogAroundDocController', function ($rootScope, $scope, $routeParams,
                                               $q, couchDB, couchView) {
   $scope.channel = $rootScope.title = $routeParams.channel;
   $scope.docid = $routeParams.docid;
   $scope.rows = [];

   var db = couchDB(URL_BASE + 'api');
   db.getDoc($routeParams.docid).then(function (doc) {

      var view1 = couchView(URL_BASE + 'ddoc/_view/channel', {
         include_docs: true,
         descending: true,
         limit: 8,
         startkey: [doc.channel, doc.timestamp],
         startkey_docid: doc._id,
         endkey: [doc.channel, 0]
      });
      var view2 = couchView(URL_BASE + 'ddoc/_view/channel', {
         include_docs: true,
         descending: false,
         limit: 8,
         startkey: [$routeParams.channel, doc.timestamp],
         startkey_docid: doc._id,
         endkey: [$routeParams.channel, {}]
      });

      $q.all([view1.get(), view2.get()]).then(function (views) {
         $scope.rows.push.apply($scope.rows, views[0].rows);
         $scope.rows.shift(); // we get the same row twice
         $scope.rows.push.apply($scope.rows, views[1].rows);
      });

      var pager1 = view1;
      $scope.prevClick = function() {
         // because of "descending: true" we go back towards the past,
         // so counterintuitively use .loadAfter()
         pager1 = pager1.loadAfter();
         pager1.get().then(function (result) {
            $scope.rows.push.apply($scope.rows, result.rows);
         })
      };

      var pager2 = view2;
      $scope.nextClick = function() {
         pager2 = pager2.loadAfter();
         pager2.get().then(function (result) {
            $scope.rows.push.apply($scope.rows, result.rows);
         })
      };
   })

})

