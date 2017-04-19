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

  $scope.show_search = () ->
    if $state.$current.name.indexOf("candidatures")>-1
      return false
    return true

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
   $rootScope.logout = (route) ->
     delete $http.defaults.headers.common.Authorization
     Logout.post({}, [headers={}])
     .then((auth) ->
           localStorage.removeItem("token")
           $rootScope.user = {}
           delete $http.defaults.headers.common.Authorization
           authManager.unauthenticate()
           if(route)
             $state.go(route)
         , () ->
           console.log("error Logout")
           localStorage.removeItem("token")
           $rootScope.user = {}
           delete $http.defaults.headers.common.Authorization
           authManager.unauthenticate()
     )

)

.controller('ArtistListingController', ($scope, Students, $state) ->
  $scope.letter = $state.params.letter || "a"
  $scope.artists = Students.getList({user__last_name__istartswith: $scope.letter, limit: 200}).$object
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

.controller('ArtistController', ($scope, $stateParams, Students, Artists, Artworks) ->
  $scope.artworks = []

  Artists.one().one($stateParams.id).get().then((artist) ->
    $scope.artist = artist

    # Fetch artworks
    for artwork_uri in $scope.artist.artworks
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
    AmeRestangular.all("").get('apiresult.json',{"search": search, "flvfile": "true", "previewsize":"scr"}, {authorization: undefined} ).then((ame_artwork) ->
      for archive in ame_artwork
        # valid reference id Fresnoy => id AME

        if parseInt(archive.field201) == $scope.artwork.id

          if archive.flvpath

            $scope.ame_artwork_gallery.media.push({
              picture : archive.flvthumb.replace("http://", "https://").replace(":80", ":443")
              medium_url : $sce.trustAsResourceUrl(archive.flvpath.replace("http://", "https://").replace(":80", ":443"))
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

.controller('CandidaturesController', ($rootScope, $scope, $stateParams, $location, Candidatures, Galleries, Media, RestangularV2, ArtistsV2, Users,
  ISO3166, cfpLoadingBar) ->
  # init
  $scope.candidatures = []
  $scope.candidat_id = $stateParams.id
  console.log ("Candidatures : ")
  console.log($scope.candidat_id)
  console.log(stateParams)
  # order
  # none = 1 | true = 2 | false = 3
  $scope.select_criteres = [
    {title: 'Toutes', sortby: {"search": ""}, count:0 },
    {title: 'Courrier', sortby: {"physical_content": 2, "physical_content_received": 3}, count:0},
    {title: 'En attente de validation', sortby: {"application_completed": 2, "application_complete": 3}, count:0},
    {title: 'Visées', sortby: {"application_complete": 2}, count:0},
    {title: 'Selectionnés pour l\'entretien', sortby: {"selected_for_interview": 2}, count:0},
    {title: 'Admis', sortby: {"selected": 2}, count:0},
    {title: 'Admis sur liste d\'attente', sortby: {"wait_listed": 2}, count:0},
  ]
  $scope.select_orders = [
      {title: "Numéro d'inscription", value: {ordering: "id"}}
      {title: "Nationalité", value: {ordering: "artist__user__profile__nationality"}},
      {title: "Nom", value: {ordering: "artist__user__last_name"}},
  ]

  $scope.getCandidaturesLength = (sort) ->
    Candidatures.getList(sort.sortby).then((c) -> sort.count = c.length )

  $scope.critere = if $stateParams.sortby then $stateParams.sortby else "3"
  for item, value of $scope.select_criteres then $scope.getCandidaturesLength(value)

  $scope.order = if $stateParams.orderby then $stateParams.orderby else "2"
  $scope.asc = if $stateParams.asc then $stateParams.asc else "true"
  $scope.loading = cfpLoadingBar
  # language / country
  $scope.country = ISO3166
  $scope.LANGUAGES_NAME = languageMappingList
  $scope.LANGUAGES_NAME_short = {}
  $scope.LANGUAGES_NAME_short[obj.split("-")[0]] = val for obj, val of languageMappingList

  $scope.getCandidatures = (sort, order) ->
    criteres = Object.assign(sort.sortby, order.value)
    if($scope.asc == 'false') then criteres.ordering = "-"+criteres.ordering
    arr = []
    Candidatures.getList(criteres).then((candidatures) ->
      for candidature in candidatures
          artist_id = candidature.artist.match(/\d+$/)[0]
          candidature.progress = $scope.get_candidature_progress(candidature)
          arr.push(candidature)

          if(candidature.application_completed)
              ArtistsV2.one(artist_id).withHttpConfig({ cache: true}).get().then((artist) ->
                  current_cantidature = _.filter(candidatures, (c) -> return c.artist == artist.url)
                  current_cantidature[0].artist = artist
                  # user
                  user_id = artist.user.match(/\d+$/)[0]
                  current_cantidature[0].artist.user = Users.one(user_id).get().then((user_infos) ->
                    current_cantidature[0].artist.user = user_infos
                  )
              )
    )
    return arr

  $scope.candidatures = $scope.getCandidatures($scope.select_criteres[$scope.critere], $scope.select_orders[$scope.order])

  $scope.get_candidature_progress = (candidature) ->
    candidature_progress = candidature_total = user_progress = user_total = 0
    candidature_plain = candidature.plain()
    for field, value of candidature_plain
      candidature_total++
      if(value && value != null && value != "" && value != undefined )
        candidature_progress++
    candidature_total -= 6
    candidature_progress +=2

    c = Math.round(Math.min((candidature_progress/candidature_total )*100, 100))
    return c

  $scope.search = (search) ->
    $(".candidat-card").each((item) ->
        text = $(this).text().toLowerCase()
        search = search.toLowerCase()
        $(this).show()
        if(text.indexOf(search)==-1)
          $(this).hide()

    )
    return true

  # make CSV file
  $scope.today = new Date()
  $scope.make_data = () ->
    csvContent = ""
    csv = []
    for line in document.querySelectorAll("table#data_candidatures tr")
        row = []
        for col in line.querySelectorAll("td, th")
            t = $(col).text().replace(/\s\s+/g,' ')
            row.push(t)
        csv.push(row.join(";"))

    csvContent += "\ufeff"+csv.join('\n')
    csvFile  = new Blob([csvContent], {type: "text/csv;charset=utf-8"})
    return window.URL.createObjectURL(csvFile)

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

  $scope.singleLightbox = (url, description) ->
    # config image gallery
    image =
      isvideo: new RegExp("aml|player.vimeo|mp4","gi").test(url);
      iframe: /(\.pdf|vimeo\.com|youtube\.com|youtu\.be)/i.test(url)
      description: description
    # embed video youtube
    url = url.replace(/^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?/gm, 'https://www.youtube.com/embed/$5');
    url = url.replace(/^https?:\/\/(?:www\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/([^\/]*)\/videos\/|album\/(\d+)\/video\/|)(\d+)(?:$|\/|\?)(.*)/g, "https://player.vimeo.com/video/$3")
    # when url is image set picture var, otherwise set medium_url
    if(/\.(jpe?g|png|gif|bmp)/i.test(url)) then image.picture= $sce.trustAsResourceUrl(url)
    else  image.medium_url= $sce.trustAsResourceUrl(url)
    Lightbox.one_media = true
    Lightbox.openModal([image], 0)

  loadCandidat = (id) ->
      Candidatures.one(id).get().then((candidature) ->
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

  loadCandidat($stateParams.id)
)
