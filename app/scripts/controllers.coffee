# -*- tab-width: 2 -*-
"use strict"

angular.module('memoire.controllers', ['memoire.services'])

.controller('ArtistListingController', ($scope, Artists) ->
  $scope.artists = Artists.getList().$object
)

.controller('SchoolController', ($scope, Promotions, Students) ->
  $scope.promotions = Promotions.getList({order_by: "-starting_year"}).$object
)

.controller('PromotionController', ($scope, $stateParams, Students) ->
  $scope.students = Students.getList({promotion: $stateParams.id, limit: 100}).$object
)

.controller('ArtistController', ($scope, $stateParams, Artists) ->
  $scope.artists = Artists.one($stateParams.id).get().$object
)

.controller('ArtworkController', ($scope, $stateParams, Artworks) ->
  $scope.artwork = Artworks.one($stateParams.id).get().$object
)

.controller('StudentController', ($scope, $stateParams, Students, Artworks) ->
  $scope.student = null
  $scope.artworks = []

  Students.one().one($stateParams.id).get().then((student) ->
    $scope.student = student
    for artwork_uri in $scope.student.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)
