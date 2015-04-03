# -*- tab-width: 2 -*-
"use strict"

angular.module('memoire.controllers', ['memoire.services'])

.controller('ArtistListingController', ($scope, Artists) ->
  $scope.artists = Artists.getList().$object
)

.controller('SchoolController', ($scope, Promotions, Students) ->
  $scope.promotions = Promotions.getList({order_by: "-starting_year"}).$object
)

.controller('PromotionController', ($scope, $stateParams, Students, Promotions) ->
  $scope.promotion = Promotions.one($stateParams.id).get().$object

  $scope.students = Students.getList({promotion: $stateParams.id, limit: 100}).$object
)

.controller('ArtistController', ($scope, $stateParams, Artists) ->
  $scope.artists = Artists.one($stateParams.id).get().$object
)

.controller('ArtworkController', ($scope, $stateParams, Artworks, Events) ->
  $scope.artwork = null
  $scope.events = []

  Artworks.one().one($stateParams.id).get().then((artwork) ->
    $scope.artwork = artwork
    for event_uri in $scope.artwork.events
      matches = event_uri.match(/\d+$/)
      if matches
        event_id = matches[0]
        Events.one(event_id).get().then((event) ->
          $scope.events.push(event)
        )
  )

)

.controller('StudentController', ($scope, $stateParams, Students, Artworks, Promotions) ->
  $scope.student = null
  $scope.promotion = null
  $scope.artworks = []

  Students.one().one($stateParams.id).get().then((student) ->
    $scope.student = student

    # Fetch promotion
    matches = student.promotion.match(/\d+$/)
    if matches
      promotion_id = matches[0]
      Promotions.one(promotion_id).get().then((promotion) ->
        $scope.promotion = promotion
      )

    # Fetch artworks
    for artwork_uri in $scope.student.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)
