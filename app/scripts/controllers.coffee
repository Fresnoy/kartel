# -*- tab-width: 2 -*-
"use strict"

angular.module('memoire.controllers', ['memoire.services'])

.controller('QuickSearch', ($scope, $q, $state, Restangular) ->
  $scope.selected = null

  $scope.goTo = ($item, $model, $label) ->
    # Extract the id
    matches = $item.resource_uri.match(/\d+$/)
    if matches
      id = matches[0]

    if $item.resource_uri.search("production") != -1
      $state.go("artwork-detail", {id: id})

    else if $item.resource_uri.search("student") != -1
      $state.go("school.student", {id: id})


  $scope.search = (value) ->
    artworks = Restangular.all('production/artwork').customGET('search', {q: value}).then((response) ->
      return response.objects
    )

    students = Restangular.all('school/student').customGET('search', {q: value}).then((response) ->
      return response.objects
    )

    $q.all([students, artworks]).then((results) ->
      return _.flatten(_.map(results, _.values))
    )
)

.controller('NavController', ($scope, $rootScope, $http, Login, Logout, jwtHelper, Users, authManager, Candidatures, $state) ->
  $rootScope.candidatures = Candidatures.getList().$object

  $scope.user_infos =
      username:""
      email:""
      password:""
      error:""

  if(localStorage.getItem('token'))
    user_id = jwtHelper.decodeToken(localStorage.getItem('token')).user_id
    Users.one(user_id).get().then((user) ->
      $rootScope.user = user
    )

  $scope.login = (form, params) ->
    delete $http.defaults.headers.common.Authorization
    params.error=""
    Login.post(params)
    .then((auth) ->
          localStorage.setItem('token', auth.token)
          $http.defaults.headers.common.Authorization = "JWT "+ localStorage.getItem('token')
          authManager.authenticate()
          Users.one(auth.user.pk).get().then((user) ->
            $rootScope.user = user
            $state.reload()
          )
        , (error) ->
          params.error = error.data
   )
   # logout
   $scope.logout = (route) ->
     Logout.post({},{},{}).then((auth) ->
         localStorage.removeItem("token")
         delete $http.defaults.headers.common.Authorization
         authManager.unauthenticate()
         $rootScope.user = {}
     )

)

.controller('ArtistListingController', ($scope, Artists, $state) ->
  $scope.letter = $state.params.letter || "a"
  $scope.artists = Artists.getList({user__last_name__istartswith: $scope.letter, limit: 200}).$object
  $scope.alphabet = "abcdefghijklmnopqrstuvwxyz".split("")
)

.controller('ArtworkListingController', ($scope, Artworks, $state) ->
  $scope.letter = $state.params.letter || "a"
  $scope.offset = parseInt($state.params.offset) || 0
  $scope.limit = 200
  $scope.artworks = Artworks.getList({title__istartswith: $scope.letter, limit: $scope.limit, offset:$scope.offset }).$object
  $scope.alphabet = "abcdefghijklmnopqrstuvwxyz".split("")
)

.controller('ArtworkGenreListingController', ($scope, Artworks, $state) ->
  $scope.genre = $state.params.genre || ""
  $scope.artworks = Artworks.getList({genres: $scope.genre, limit: 200}).$object
)


.controller('SchoolController', ($scope, $state, Promotions, Students) ->
  $scope.promotions = []

  Promotions.getList({order_by: "-starting_year"}).then((promotions) ->
    $scope.promotions = promotions
  )

)


.controller('PromotionController', ($scope, $stateParams, Students, Promotions) ->


  $scope.promotion = Promotions.one($stateParams.id).get().$object

  $scope.students = Students.getList({promotion: $stateParams.id, limit: 500}).$object
)

.controller('ArtistController', ($scope, $stateParams, Artists, Artworks) ->
  $scope.student = null
  $scope.artworks = []

  Artists.one().one($stateParams.id).get().then((artist) ->
    $scope.student = {}
    $scope.student.artist = artist
    $scope.student.user = artist.user

    # Fetch artworks
    for artwork_uri in $scope.student.artist.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)

.controller('ArtworkController', ($scope, $stateParams, $sce, $http, Lightbox, Artworks, AmeRestangular,  Events, Collaborators, Partners) ->
  $scope.artwork = null
  $scope.events = []


  $scope.main_picture_gallery = {media: []}
  # ame gallery vars for gallery
  $scope.ame_artwork_gallery = {media: []}
  # ame available for template
  $scope.ame_access = true

  Artworks.one().one($stateParams.id).get().then((artwork) ->
    $scope.artwork = artwork
    console.log(artwork)
    for event_uri in $scope.artwork.events
      matches = event_uri.match(/\d+$/)
      if matches
        event_id = matches[0]
        Events.one(event_id).get().then((event) ->
          $scope.events.push(event)
        )

    for collaborator_uri,key in $scope.artwork.collaborators
      if typeof collaborator_uri.match == Function
        matches = collaborator_uri.match(/\d+$/)
        if matches
          collaborator_id = matches[0]
          $scope.artwork.collaborators[key] = Collaborators.one(collaborator_id).get().$object


    for partner_uri,key in $scope.artwork.partners
      if typeof partner_uri.match == Function
        matches = partner_uri.match(/\d+$/)
        if matches
          partner_id = matches[0]
          $scope.artwork.partners[key] = Partners.one(partner_id).get().$object



    search = ""
    #return all artwork video and filtre with idFrezsnoy - TODO search idFresnoy in api
    # AmeRestangular.setDefaultHeaders({'Content-Type': 'charset=UTF-8'})
    AmeRestangular.all("api_search/").get('',{"search": search, "flvfile": "true", "previewsize":"scr"}, {authorization: undefined} ).then((ame_artwork) ->
      for archive in ame_artwork
        # valid reference id Fresnoy => id AME

        if parseInt(archive.field201) == $scope.artwork.id

          if archive.flvpath

            $scope.ame_artwork_gallery.media.push({
              picture : archive.flvthumb
              medium_url : $sce.trustAsResourceUrl(archive.flvpath)
              description : archive.field8 #media ame title
           })

    , (response) ->
      #erreur service
      $scope.ame_access = false
    )
    # Fake a gallery for the main visual so we can reuse the gallery
    # component
    $scope.main_picture_gallery.media.push({
      picture: artwork.picture
      description: 'Visuel principal'
    })



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
    for artwork_uri in $scope.student.artist.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)

.controller('CandidaturesController', ($rootScope, $scope, Candidatures, RestangularV2, ArtistsV2, Users,
  ISO3166) ->
  # init
  $scope.candidatures = []
  $scope.select_critere =
    'Tri par' : ""
    'Candidatures Completes' : "application_complete"
    'Selectionnés pour les interview' : "selected_for_interview"
    'Selectionnés' : "selected_for_interview"
    'Liste d\'attente' : "wait_listed"

  $scope.country = ISO3166
  $scope.LANGUAGES_NAME = languageMappingList
  $scope.LANGUAGES_NAME_short = {}
  $scope.LANGUAGES_NAME_short[obj.split("-")[0]] = val for obj, val of languageMappingList

  Candidatures.getList({limit: 500}).then((candidatures) ->
    for candidature in candidatures
      artist_id = candidature.artist.match(/\d+$/)[0]
      if(candidature.application_completed || candidature.physical_content)
        $scope.candidatures.push(candidature)
        ArtistsV2.one(artist_id).get().then((artist) ->
            current_cantidature = _.filter(candidatures, (c) -> return c.artist == artist.url)
            current_cantidature[0].artist = artist
            for website in artist.websites
                website_id = website.match(/\d+$/)[0]
                RestangularV2.one('common/website', website_id).get().then((response_website) ->
                    find_website = artist.websites.indexOf(response_website.url)
                    artist.websites[find_website] = response_website
                )
            user_id = artist.user.match(/\d+$/)[0]
            current_cantidature[0].artist.user = Users.one(user_id).get().then((user_infos) ->
              current_cantidature[0].artist.user = user_infos
            )
      )
  )

  $scope.getStateCandidature = (candidature) ->
    $state = 0
    if(candidature.application_complete)
      $state = 1
    if(candidature.selected_for_interview)
      $state = 2
    if(candidature.wait_listed)
      $state = 3
    if(candidature.selected)
      $state = 4
    return $state


  $scope.show_candidat = (candidat, field, value) ->
    if ($scope.critere)
      return candidat[$scope.critere] == $scope.critere_bool
    return true


  $scope.search = (search) ->
    $(".candidat-card").each((item) ->
        text = $(this).text().toLowerCase()
        search = search.toLowerCase()
        $(this).show()
        if(text.indexOf(search)==-1)
          $(this).hide()

    )
    return true




)

.controller('CandidatController', ($rootScope, $scope, ISO3166, $stateParams, RestangularV2, Candidatures, ArtistsV2,
        WebsiteV2, Users, Galleries, Media, Lightbox, $sce) ->
  # init

  $scope.candidature = []
  $scope.artist = []
  $scope.administrative_galleries = []
  $scope.artwork_galleries = []

  $scope.gender =
    M: fr: "Homme", en: "Male"
    F: fr: "Femme", en: "Female"
    T: fr: "Transgenre", en: "Transgender"
    O: fr: "Autre", en: "Other"

  $scope.country = ISO3166
  $scope.LANGUAGES_NAME = languageMappingList
  $scope.LANGUAGES_NAME_short = {}
  $scope.LANGUAGES_NAME_short[obj.split("-")[0]] = val for obj, val of languageMappingList

  $scope.trustSrc = (src) ->
    return $sce.trustAsResourceUrl(src)


  loadGalleries = (galleries) ->

    for gallery in galleries
      gallery_id = gallery.match(/\d+$/)[0]
      Galleries.one(gallery_id).get().then((gallery_infos) ->
        gallery_index = galleries.indexOf(gallery_infos.url)
        galleries[gallery_index] = gallery_infos

        for medium in gallery_infos.media
          medium_id = medium.match(/\d+$/)[0]
          Media.one(medium_id).get().then((media) ->
            media_index = galleries[gallery_index].media.indexOf(media.url)
            gallery_infos.media[media_index] = media
          )
      )
    return galleries





  $scope.lightbox = (gallery, index) ->
    Lightbox.openModal(gallery, index)

  Candidatures.one($stateParams.id).get().then((candidature) ->
    $scope.candidature = candidature


    artist_id = candidature.artist.match(/\d+$/)[0]
    ArtistsV2.one(artist_id).get().then((artist) ->
        $scope.artist = artist
        for website in artist.websites
            website_id = website.match(/\d+$/)[0]
            RestangularV2.one('common/website', website_id).get().then((response_website) ->
                find_website = artist.websites.indexOf(response_website.url)
                artist.websites[find_website] = response_website
            )
        user_id = artist.user.match(/\d+$/)[0]
        $scope.artist.user = Users.one(user_id).get().then((user_infos) ->
          $scope.artist.user = user_infos
        )

    )
    gallery_id = candidature.cursus_justifications.match(/\d+$/)[0]
    Galleries.one(gallery_id).get().then((gallery_infos) ->
      candidature.cursus_justifications = gallery_infos

      for medium in gallery_infos.media
        medium_id = medium.match(/\d+$/)[0]
        Media.one(medium_id).get().then((media) ->
          media_index = gallery_infos.media.indexOf(media.url)
          gallery_infos.media[media_index] = media
        )

    )

  )
)
