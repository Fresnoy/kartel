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
  # $rootScope.candidatures = Candidatures.getList().$object

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

  Promotions.getList({order_by: "-starting_year", limit: 200}).then((promotions) ->
    $scope.promotions = promotions
  )

)


.controller('PromotionController', ($scope, $stateParams, Students, Promotions) ->


  $scope.promotion = Promotions.one($stateParams.id).get().$object
  $scope.students = Students.getList({promotion: $stateParams.id, order_by:'user__last_name', limit: 500}).$object
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

.controller('ArtworkController', ($scope, $stateParams, $sce, $http, Lightbox, Artworks, AmeRestangular, Events, Collaborators, Partners, Candidatures) ->
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

    $scope.artwork.partners.tasks = {}
    for partner in $scope.artwork.partners
       if partner.task
          if !$scope.artwork.partners.tasks[partner.task.label]
            $scope.artwork.partners.tasks[partner.task.label] = []
          $scope.artwork.partners.tasks[partner.task.label].push(partner.organization)

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
    #
    $scope.history = null
    for authors in artwork.authors
        critere = {search: authors.user.username}
        Candidatures.getList(critere).then((candidatures) ->
            if(candidatures.length)
                production_year = artwork.production_date.split("-")[0]
                candidature = candidatures[0]
                $scope.history = {candidature: candidature}
                # candidature + 1 an = premiere oeuvre
                if(candidature.created_on.indexOf((production_year-1))>=0 )
                   $scope.history.candidature.projet_1 = candidature.considered_project_1
                # candidature + 1 an = deuxieme oeuvre
                if(candidature.created_on.indexOf((production_year-2))>=0 )
                  $scope.history.candidature.projet_2 = candidature.considered_project_2
        )
  )
  $scope.singleLightboxIframe = (url) ->
    # config image gallery
    image =
      isvideo: false
      iframe: true
      original: url
    image.medium_url= $sce.trustAsResourceUrl(url)
    Lightbox.one_media = true
    Lightbox.openModal([image], 0)
)

.controller('StudentController', ($scope, $rootScope, $stateParams, Students, Artworks, Promotions, Candidatures, ArtistsV2, Users, ISO3166) ->
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

    # Get more infos from candidature
    $scope.more = null
    $scope.country = ISO3166
    critere = {search: student.user.username, ordering:'-id'}
    Candidatures.getList(critere).then((candidatures) ->
          if(candidatures.length)
              $scope.more = candidatures[0]
              $scope.more.artist = ArtistsV2.one($scope.more.artist.split("/").reverse()[0]).get().then((artist) ->
                $scope.more.artist = artist
                $scope.more.artist.user = Users.one(artist.user.split("/").reverse()[0]).get().then((user) ->
                  $scope.more.artist.user = user
                  console.log($scope.more)
                )
              )
      )

  )


)

.controller('CandidaturesController', ($rootScope, $scope, $stateParams, $location, Candidatures, Galleries, Media, RestangularV2, ArtistsV2, Users,
  ISO3166, cfpLoadingBar) ->
  # init
  $scope.candidatures = []
  $scope.candidat_id = $stateParams.id

  current_year = new Date().getFullYear()
  # order
  # none = 1 | true = 2 | false = 3
  $scope.select_criteres = [
    {key:0, title: 'Toutes', sortby: {'campaign__is_current_setup':'true', "unselected": 'false'}, count:0 },
    {key:1, title: 'Refusées', sortby: {'campaign__is_current_setup':'true', "unselected":'true'}, count:0 },
    {key:2, title: 'Non finalisées', sortby: {'campaign__is_current_setup':'true', "unselected": 'false', "application_completed": 'false'}, count:0},
    {key:3, title: 'En attente de validation', sortby: {'campaign__is_current_setup':'true', "unselected": 'false', "application_completed":'true', "application_complete": 'false'}, count:0},
    {key:4, title: 'Visées', sortby: {'campaign__is_current_setup':'true', "unselected": 'false', "application_complete":'true'}, count:0},
    {key:5, title: 'Entretien : liste d\'attente', sortby: {'campaign__is_current_setup':'true', "unselected": 'false', "wait_listed_for_interview":'true'}, count:0},
    {key:6, title: 'Entretien : Selectionnés', sortby: {'campaign__is_current_setup':'true', "unselected": 'false', "selected_for_interview":'true'}, count:0},
    {key:7, title: 'Admis : liste d\'attente', sortby: {'campaign__is_current_setup':'true', "unselected": 'false', "wait_listed":'true'}, count:0},
    {key:8, title: 'Admis', sortby: {'campaign__is_current_setup':'true', "unselected": 'false', "selected":'true'}, count:0},
  ]
  $scope.select_orders = [
      {title: "Numéro d'inscription", value: {ordering: "id"}}
      {title: "Nationalité", value: {ordering: "artist__user__profile__nationality"}},
      {title: "Nom", value: {ordering: "artist__user__last_name"}},
  ]

  $scope.getCandidaturesLength = (sort) ->
    Candidatures.getList(sort.sortby).then((c) -> sort.count = c.length )

  $scope.critere = if $stateParams.sortby then $stateParams.sortby else $scope.select_criteres.findIndex((crit) -> crit.title =='Entretien : Selectionnés')
  for item, value of $scope.select_criteres then $scope.getCandidaturesLength(value)

  $scope.order = if $stateParams.orderby then $stateParams.orderby else $scope.select_orders.findIndex((order) -> order.title =='Nom')
  $scope.asc = if $stateParams.asc then $stateParams.asc else 'true'
  $scope.loading = cfpLoadingBar
  # language / country
  $scope.country = ISO3166
  $scope.LANGUAGES_NAME = languageMappingList
  $scope.LANGUAGES_NAME_short = {}
  $scope.LANGUAGES_NAME_short[obj.split("-")[0]] = val for obj, val of languageMappingList

  $scope.getCandidatures = (sort, order) ->
    criteres = _.extend(sort.sortby, order.value)
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
              if(candidature.cursus_justifications != null)
                  gallery_id = candidature.cursus_justifications.match(/\d+$/)[0]
                  Galleries.one(gallery_id).get().then((gallery_infos) ->
                    current_cantidature = _.filter(candidatures, (c) -> return c.cursus_justifications == gallery_infos.url)
                    current_cantidature[0].cursus_justifications = gallery_infos

                    for medium in gallery_infos.media
                      medium_id = medium.match(/\d+$/)[0]
                      Media.one(medium_id).get().then((media) ->
                        media_index = gallery_infos.media.indexOf(media.url)
                        gallery_infos.media[media_index] = media
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
            t = $(col).text().replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n|&#10;&#13;|&#13;&#10;|&#10;|&#13;)/g, ' ')
            t = $(col).text().replace(/\s+/g,' ')
            row.push(t)
        csv.push(row.join(";"))

    csvContent += "\ufeff"+csv.join('\n')
    csvFile  = new Blob([csvContent], {type: "text/csv;charset=utf-8"})
    return window.URL.createObjectURL(csvFile)

)

.controller('CandidatController', ($rootScope, $scope, ISO3166, $stateParams, RestangularV2, Candidatures, ArtistsV2,
        WebsiteV2, Users, Galleries, Media, Lightbox, clipboard, $sce) ->
  # init
  $scope.candidature = []
  $scope.artist = []
  $scope.administrative_galleries = []
  $scope.artwork_galleries = []

  # observation
  obj_observation = {}

  add_observation = () ->
    # set default values
    if(!obj_observation[$rootScope.user.username])
      obj_observation[$rootScope.user.username] = ""
    if(!obj_observation['jury'])
      obj_observation.jury = ''
    # encode values
    str_observation = JSON.stringify(obj_observation)
    # save values
    $scope.candidature.patch({observation: str_observation})

  $scope.$watch("candidature.observation", (newValue, oldValue) ->
    # set default values
    if(newValue == "")
      add_observation()
    # displays values
    if(newValue)
      # decode text
      obj_observation = JSON.parse(newValue)
      # assign text to user / jury
      $scope.jury_observation = obj_observation.jury
      $scope.personal_observation = obj_observation[$rootScope.user.username]
  )
  $scope.add_observation =  (field, value) ->
      obj_observation[field] = value
      add_observation()

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
      isvideo: new RegExp("aml|ame|youtu|player.vimeo|mp4","gi").test(url);
      iframe: /(\.pdf|vimeo\.com|youtube\.com|youtu\.be)/i.test(url)
      original: url
      description: description
    # embed video youtube
    url = url.replace(/^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?/gm, 'https://www.youtube.com/embed/$5');
    url = url.replace(/^https?:\/\/(?:www\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/([^\/]*)\/videos\/|album\/(\d+)\/video\/|)(\d+)(?:$|\/|\?)(.*)/g, "https://player.vimeo.com/video/$3")
    # when url is image set picture var, otherwise set medium_url
    if(/\.(jpe?g|png|gif|bmp|tif)/i.test(url)) then image.picture = url
    else  image.medium_url= $sce.trustAsResourceUrl(url)
    Lightbox.one_media = true
    Lightbox.openModal([image], 0)

  loadCandidat = (id) ->
      Candidatures.one(id).get().then((candidature) ->
        $scope.candidature = candidature
        $scope.itw_date = new Date(candidature.interview_date)
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
        if(candidature.cursus_justifications != null)
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

  $scope.date = (date) ->
    return new Date(date)

  # PASSWORD clipboard
  $scope.password_to_clipboard = null
  $scope.copySuccess = () ->
    $scope.password_to_clipboard = true

  $scope.copyFail = (err) ->
    $scope.password_to_clipboard = false
  $scope.resetCopy = () ->
    $scope.password_to_clipboard = null


  # Search binominal
  $scope.binominal_link_id = ""
  $scope.$watch("candidature", (newValue, oldValue) ->
    if(newValue)
      # console.log(newValue)
      candidat = newValue
      # cherche à faire un lien avec le binome
      if(candidat.binomial_application)
          binominal_split = candidat.binomial_application_with.split(" ")
          # cherche avec ce qu'a remplis le candidat (avec un peu de chance, le nom / prénom)
          for name in binominal_split
            critere = {search: name, campaign__is_current_setup:"true"}
            Candidatures.getList(critere).then((candidatures) ->
              if(candidatures.length && $scope.binominal_link_id=="")
                $scope.binominal_link_id = candidatures[0].id
            )
  )


)

.controller('CandidaturesConfigurationController', ($rootScope, $scope, RestangularV2, Campaigns, PromotionsV2) ->
  $scope.configuration = []
  $scope.promotion = []

  $scope.now = () ->
    return new Date(Date.now())
  $scope.date = (date) ->
    return new Date(date)

  Campaigns.getList({is_current_setup: "true"}).then((current_campaign) ->
    $scope.configuration = current_campaign[0]
    $scope.date_of_birth_max = new Date($scope.configuration.date_of_birth_max)
    $scope.interviews_publish_date = new Date($scope.configuration.interviews_publish_date)
    $scope.selected_publish_date = new Date($scope.configuration.selected_publish_date)
    $scope.candidature_date_end = new Date($scope.configuration.candidature_date_end)
    # get promo infos
    promo_id = $scope.configuration.promotion.match(/\d+$/)[0]
    RestangularV2.one("school/promotion/"+promo_id).get().then((promo) ->
        $scope.promo_name = promo.name
        $scope.promotion = promo
    )
  )
)
