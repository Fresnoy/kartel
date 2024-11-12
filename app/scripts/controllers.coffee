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

.controller('NavController', ($scope, $rootScope, $http, Login, Logout, LoginK, LogoutK, APIK, APIV2K,
                              jwtHelper, Users, authManager, $state) ->
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
    
    try user_id = jwtHelper.decodeToken(localStorage.getItem('token')).user_id
    catch e then user_id = false

    Users.one(user_id).get().then((user) ->
      $rootScope.user = user
    )

  $scope.login = (form, params) ->
    delete $http.defaults.headers.common.Authorization
    params.error=""
    Login.post(params)
    .then((auth) ->
          localStorage.setItem('token', auth.access)
          $http.defaults.headers.common.Authorization = "JWT "+ localStorage.getItem('token')
          authManager.authenticate()
          Users.one(auth.user.pk).get().then((user) ->
            $rootScope.user = user
            $state.reload()
          )
        , (error) ->
          params.error = error.data
    )
    LoginK.post(params)
    .then((authK) ->
          localStorage.setItem('Candidaturestoken', authK.access)
          APIV2K.setDefaultHeaders({Authorization: "JWT "+ authK.access});
        ,(error) ->
          console.log("Login Kapi error")
          params.error = error.data
    )
   # logout
   $rootScope.logout = (route) ->
     delete $http.defaults.headers.common.Authorization
     Logout.post({}, [headers={}])
     .then((auth) ->
           # K logout
           LogoutK.post({}, [headers={}])
           localStorage.removeItem("Candidaturestoken")

           # clean token / user
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
   $scope.toggleDarkTheme = () -> 
      $rootScope.theme = if $rootScope.theme == "darktheme" then "" else "darktheme" 

)

.controller('ArtistListingController', ($rootScope, $scope, Students, $state) ->
  $rootScope.main_title = "Kartel - Liste des artistes"
  $scope.letter = $state.params.letter || "a"
  $scope.artists = Students.getList({user__last_name__istartswith: $scope.letter, limit: 200}).$object
  $scope.alphabet = "abcdefghijklmnopqrstuvwxyz".split("")
)

.controller('ArtworkListingController', ($rootScope, $scope, Artworks, $state) ->
  $rootScope.main_title = "Kartel - Liste des œuvres"
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


.controller('SchoolController', ($rootScope, $scope, $state, Promotions, Students) ->
  $rootScope.main_title = "Kartel - Liste des promotions"
  $scope.promotions = []

  Promotions.getList({order_by: "-starting_year", limit: 200}).then((promotions) ->
    $scope.promotions = promotions
  )

)


.controller('PromotionController', ($rootScope, $scope, $stateParams, Students, Promotions) ->

  # $scope.promotion = Promotions.one($stateParams.id).get().$object
  $scope.promotion = Promotions.one($stateParams.id).get().then((promotion) ->
    # main title
    $rootScope.main_title= "Kartel - Promotion : " +promotion.name
    $scope.promotion = promotion
  )
  $scope.students = Students.getList({promotion: $stateParams.id, order_by:'user__last_name', limit: 500}).$object
)

.controller('ArtistController', ($rootScope, $scope, $stateParams, Students, Artists, Artworks) ->
  $rootScope.main_title = "Kartel - Artiste"

  $scope.artworks = []

  Artists.one().one($stateParams.id).get().then((artist) ->
    $scope.artist = artist
    name = if artist.nickname then artist.nickname else (artist.user.first_name + " " + artist.user.last_name)
    $rootScope.main_title = "Kartel - Artiste :" + name

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

.controller('ArtworkController', ($rootScope, $scope, $stateParams, $sce, $http, Lightbox, Artworks, AmeRestangular, 
                            Events, Collaborators, Partners, Candidatures) ->
  # main title
  $rootScope.main_title="Kartel - Œuvre"

  $scope.artwork = null
  $scope.events = []


  $scope.main_picture_gallery = {media: []}
  # ame gallery vars for gallery
  $scope.ame_artwork_gallery = {media: []}
  # ame available for template
  $scope.ame_access = true

  Artworks.one().one($stateParams.id).get().then((artwork) ->
    $scope.artwork = artwork

    $rootScope.main_title="Kartel - Œuvre : " + artwork.title

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
  # main title
  $rootScope.main_title="Kartel - Étudiant"

  $scope.student = null
  $scope.promotion = null
  $scope.artworks = []

  Students.one().one($stateParams.id).get().then((student) ->
    $scope.student = student
    artist = student.artist
    name = if artist.nickname then artist.nickname else (artist.user.first_name + " " + artist.user.last_name)
    $rootScope.main_title = "Kartel - Étudiant : " + name
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

.controller('CandidaturesController', ($rootScope, $scope, $stateParams, $location, 
                                       CandidaturesK, AdminCandidaturesK, GalleriesK, MediaK, 
                                       APIV2K, ArtistsK, UsersK, GraphqlK, CampaignsK,
                                       ISO3166, cfpLoadingBar) ->
  # main title
  $rootScope.main_title="Candidatures administration"

  # get setup
  $rootScope.campaign = {}
  CampaignsK.getList({is_current_setup: "true"}).then((campaigns) -> $rootScope.campaign =  campaigns[0] ).$objects

  # init
  # rootscope to synch candidatreS (left side) => sandidature (right side) changement (like observations)
  $rootScope.candidatures = []
  $scope.admin_app_id = $stateParams.id

  current_year = new Date().getFullYear()
  # plusieurs models sont utilisés : Canddatures et AdminCandidtures 
  # selon l'avancée de l'inscription : si l'utilisateur n'a pas finalisé son dossier, on a pas acces à toutes ses infos
  $scope.select_criteres = [
    {key:0, title: 'Sélectionner une option', sortby: {'search':'XXX', }, model: CandidaturesK },
    {key:1, title: 'Toutes', sortby: {'campaign__is_current_setup':'true', }, model: CandidaturesK, count:0 },
    {key:2, title: 'Non sélectionnées', sortby: {'application__campaign__is_current_setup':'true', "unselected":'true', }, model: AdminCandidaturesK, count:0 },
    {key:3, title: 'Non finalisées', sortby: {'campaign__is_current_setup':'true', "application_completed": 'false', }, model: CandidaturesK, count:0},
    {key:4, title: 'En attente de validation', sortby: {'application__campaign__is_current_setup':'true', 'application__application_completed':'true', "application_complete":'false', "unselected": 'false', }, model: AdminCandidaturesK, count:0},
    {key:5, title: 'Visées', sortby: {'application__campaign__is_current_setup':'true', "application_complete":'true'}, model: AdminCandidaturesK, count:0},
    {key:6, title: 'Entretien : liste d\'attente', sortby: {'application__campaign__is_current_setup':'true', "wait_listed_for_interview":'true'}, model: AdminCandidaturesK, count:0},
    {key:7, title: 'Entretien : Selectionnés', sortby: {'application__campaign__is_current_setup':'true', "selected_for_interview":'true'}, model: AdminCandidaturesK, count:0},
    {key:8, title: 'Admis : liste d\'attente', sortby: {'application__campaign__is_current_setup':'true', "wait_listed":'true'}, model: AdminCandidaturesK, count:0},
    {key:9, title: 'Admis', sortby: {'application__campaign__is_current_setup':'true', "unselected": 'false', "selected":'true'}, model: AdminCandidaturesK, count:0},
  ]
  $scope.select_orders = [
      {title: "Numéro d'inscription", value: {ordering: "application__id"}}
      {title: "Nationalité", value: {ordering: "application__artist__user__profile__nationality"}},
      {title: "Nom", value: {ordering: "application__artist__user__last_name"}},
  ]

  $scope.getCandidaturesLength = (sort) ->
    sort.model.getList(sort.sortby).then((c) -> sort.count = c.length )

  # define critere by URL or default if empty
  $scope.critere = if $stateParams.sortby then $stateParams.sortby else $scope.select_criteres.findIndex((crit) -> crit.title =='Sélectionner une option')
  # set the number of candidatures
  for item, value of $scope.select_criteres
      $scope.getCandidaturesLength(value)

  $scope.order = if $stateParams.orderby then $stateParams.orderby else $scope.select_orders.findIndex((order) -> order.title =='Nom')
  $scope.asc = if $stateParams.asc then $stateParams.asc else 'true'
  $scope.loading = cfpLoadingBar
  # language / country
  $scope.country = ISO3166
  $scope.LANGUAGES_NAME = languageMappingList
  $scope.LANGUAGES_NAME_short = {}
  $scope.LANGUAGES_NAME_short[obj.split("-")[0]] = val for obj, val of languageMappingList

  # console.log($scope.LANGUAGES_NAME)
  # console.log($scope.LANGUAGES_NAME_short)

  $scope.getCandidatures = (sort, order) ->
    # do nothing when key is 0
    if(sort.key == 0) 
      return
    # merge critere
    criteres = _.extend(sort.sortby, order.value)
    # inverse order
    if($scope.asc == 'false') then criteres.ordering = "-"+criteres.ordering
    # init arr candidatures
    arr = []
    
    sort.model.getList(criteres).then((candidatures) ->
      for candidature, index in candidatures
          # indication de la progression de la candidature (graphic use)
          candidature.progress = $scope.get_candidature_progress(candidature)
          # switch candidature load by model
          if(sort.model == AdminCandidaturesK)
            # need to make a function to keep 'candidature' scope when assign in asynch function
            switchAdminCandidature(candidature, arr, index)
          else if(sort.model == CandidaturesK)
            loadCandidatureChildInfos(candidature, false)
            arr.push(candidature)      
          else
            console.log("NO MODEL ???", sort.model)
    )
    return arr
    # GraphqlK.one().get({operationName:"Candidatures", query:"query Candidatures {  
    #     studentApplicationSetup(isCurrentSetup: true) {    
    #           applications {
    #             id      
    #             INE    
    #             applicationCompleted  
    #             artisticReferenciesProject1
    #             artisticReferenciesProject2
    #             binomialApplication
    #             binomialApplicationWith
    #             consideredProject1
    #             consideredProject2
    #             currentYearApplicationCount
    #             curriculumVitae
    #             doctorateInterest
    #             experienceJustification
    #             firstTime
    #             freeDocument
    #             identityCard
    #             justificationLetter
    #             lastApplicationsYears
    #             masterDegree
    #             presentationVideo
    #             presentationVideoDetails
    #             referenceLetter
    #             remark
    #             remoteInterview
    #             remoteInterviewInfo
    #             remoteInterviewType      
    #             administration {
    #                   applicationComplete
    #                   id
    #                   interviewDate
    #                   observation
    #                   positionInInterviewWaitlist
    #                   positionInWaitlist
    #                   selected
    #                   selectedForInterview
    #                   unselected
    #                   waitListed
    #                   waitListedForInterview
    #             } 
    #             artist {        
    #               displayName        
    #               user {
    #                     birthdate
    #                     birthplace
    #                     birthplaceCountry
    #                     cursus
    #                     email
    #                     familyStatus
    #                     firstName
    #                     gender
    #                     homelandAddress
    #                     homelandCountry
    #                     homelandPhone
    #                     id
    #                     motherTongue
    #                     nationality
    #                     otherLanguage
    #                     photo
    #                     socialInsuranceNumber
    #                     username        
    #               }      
    #             }      
    #             cursusJustifications {
    #                   description
    #                   id
    #                   label
    #                   media {
    #                         file
    #                         id
    #                         label
    #                   }
    #             }
    #       }  
    #   }}"}).then((candidatures) ->
    #       console.log(candidatures)
    #   )

  # getcandidatures
  $rootScope.candidatures = $scope.getCandidatures($scope.select_criteres[$scope.critere], $scope.select_orders[$scope.order])
  
  # console.log($rootScope.candidatures)
  # make function to keep admin cnadidature scope scope
  switchAdminCandidature = (admin_candidature_obj, arr, index) -> 
    

    application = loadAdminCandidatureObj(admin_candidature_obj).then((c) ->
        c.admin = admin_candidature_obj
        # arr.push(c) # random (async) push : bad order
        # not just a push to keep order
        arr[index] = c 
    )

  loadAdminCandidature = (admin_candidature_id) ->
    # Load an adminCandidature with his ID
    admin_candidature = AdminCandidaturesK.one(admin_candidature_id).get().then((admin_candidature_obj) ->
      admin_candidature = loadAdminCandidatureObj(admin_candidature_obj)
      return admin_candidature
    )
    return admin_candidature
  
  loadAdminCandidatureObj = (admin_candidature_obj) ->
      # search for application id
      candidature_id = admin_candidature_obj.application.match(/\d+$/)[0]

      candidature = loadCandidature(candidature_id, true)
      # for the then function ! 
      return candidature

  loadCandidature = (candidature_id, all_infos=false) ->
    return CandidaturesK.one(candidature_id).get().then((candidature_obj) ->
      candidature_obj = loadCandidatureChildInfos(candidature_obj, all_infos)
      return candidature_obj
    )
  
  # load artist, galleries and media
  loadCandidatureChildInfos = (candidature_obj, all_infos=false) ->
        if(all_infos)
            artist_id = candidature_obj.artist.match(/\d+$/)[0]
            promise = ArtistsK.one(artist_id).withHttpConfig({ cache: true}).get().then((artist) ->
                candidature_obj.artist = artist
                # user
                user_id = artist.user.match(/\d+$/)[0]
                candidature_obj.artist.user = UsersK.one(user_id).get().then((user_infos) ->
                   candidature_obj.artist.user = user_infos
                )
            )
            # get media  justifications
            if(candidature_obj.cursus_justifications != null)
                gallery_id = candidature_obj.cursus_justifications.match(/\d+$/)[0]
                GalleriesK.one(gallery_id).get().then((gallery_infos) ->
                  candidature_obj.cursus_justifications = gallery_infos

                  for medium in gallery_infos.media
                    medium_id = medium.match(/\d+$/)[0]
                    MediaK.one(medium_id).get().then((media) ->
                      media_index = gallery_infos.media.indexOf(media.url)
                      gallery_infos.media[media_index] = media
                    )
                )
        # all infos end
        else
          # get user info (email)
          artist_id = candidature_obj.artist.match(/\d+$/)[0]
          ArtistsK.one(artist_id).withHttpConfig({ cache: true}).get().then((artist) ->
                # user
                candidature_obj.artist = {user:null}
                user_id = artist.user.match(/\d+$/)[0]
                candidature_obj.artist.user = UsersK.one(user_id).get().then((user_infos) ->
                   candidature_obj.artist.user.email = user_infos.email
                )
          )

        
        return candidature_obj
  # end loadCandidaturesInfos



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
            # t = $(col).text().replace(/([^>\r\n]?)(\r\n|\n\r|\r|\n|&#10;&#13;|&#13;&#10;|&#10;|&#13;)/g, ' ')
            t = $(col).text().replace(/\s+/g,' ')
            # replace explicit newline by line in cell
            t = t.replace(/(\|newline\|)/g," - \u2029")
            row.push(t)
  
        csv.push(row.join(";"))

    csvContent += "\ufeff"+csv.join('\n')
    csvFile  = new Blob([csvContent], {type: "text/csv;charset=utf-8"})
    return window.URL.createObjectURL(csvFile)

)

.controller('CandidatController', ($rootScope, $scope, ISO3166, $stateParams, APIV2K, 
        CandidaturesK, AdminCandidaturesK, ArtistsK,
        WebsiteK, UsersK, GalleriesK, MediaK, Lightbox, clipboard, $sce, $filter) ->
  # init
  $scope.candidature = []
  $scope.artist = []
  $scope.administrative_galleries = []
  $scope.artwork_galleries = []

  # delete observation

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
      isvideo: new RegExp("aml|ame|youtu|vimeo|mp4","gi").test(url);
      iframe: /(\.pdf|vimeo\.com|youtube\.com|youtu\.be)/i.test(url)
      original: url
      description: description
    # embed video youtube
    url = url.replace(/^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?/gm, 
                     'https://www.youtube.com/embed/$5?rel=0');
    # embed video vimeo
    url = url.replace(/^https?:\/\/(?:www\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/([^\/]*)\/videos\/|album\/(\d+)\/video\/|)(\d+)(?:$|\/|\?)(.*)/g, 
                      "https://player.vimeo.com/video/$3?h=$4&quality=1080p")
    # when url is image set picture var, otherwise set medium_url
    if(/\.(jpe?g|png|gif|bmp|tif|heic)/i.test(url)) then image.picture = url
    else  image.medium_url= $sce.trustAsResourceUrl(url)
    Lightbox.one_media = true
    Lightbox.openModal([image], 0)

  loadCandidat = (id) ->
      
      AdminCandidaturesK.one(id).get().then((admin_candidature) ->
          # get application id
          # console.log("admin loaded", admin_candidature)
          candidature_id = admin_candidature.application.match(/\d+$/)[0]

          CandidaturesK.one(candidature_id).get().then((candidature) ->

            # set root vars
            $scope.candidature = candidature
            $scope.candidature.admin = admin_candidature
          
            $scope.itw_date = if (candidature.interview_date) then new Date(candidature.interview_date) else new Date()
            # 
            artist_id = candidature.artist.match(/\d+$/)[0]

            ArtistsK.one(artist_id).get().then((artist) ->
                $scope.artist = artist
                # load artist websites
                # load artist websites
                for website in artist.websites
                    website_id = website.match(/\d+$/)[0]
                    APIV2K.one('common/website', website_id).get().then((response_website) ->
                        find_website = artist.websites.indexOf(response_website.url)
                        artist.websites[find_website] = response_website
                    )
                user_id = artist.user.match(/\d+$/)[0]
                $scope.artist.user = UsersK.one(user_id).get().then((user_infos) ->
                  $scope.artist.user = user_infos
                  # add infos under videos
                  $scope.candidature.video_details_and_more = candidature.presentation_video_details
                  $scope.candidature.video_details_and_more += "\n_______\n"+ $filter('ageFilter')(user_infos.profile.birthdate) + " ans\n Niveau : "
                  $scope.candidature.video_details_and_more += if candidature.master_degree == "Y" then "Master" else if candidature.master_degree =="P" then "Master en cours" else "Bac + 7 ans d'experiences"
                )
            )
            
            # get justifications files
            if(candidature.cursus_justifications != null)
                gallery_id = candidature.cursus_justifications.match(/\d+$/)[0]
                GalleriesK.one(gallery_id).get().then((gallery_infos) ->
                  candidature.cursus_justifications = gallery_infos

                  for medium in gallery_infos.media
                    medium_id = medium.match(/\d+$/)[0]
                    MediaK.one(medium_id).get().then((media) ->
                      media_index = gallery_infos.media.indexOf(media.url)
                      gallery_infos.media[media_index] = media
                    )
                )
          )
      )

  if $stateParams.id
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
  setBinominalLinkCandidat = (admincandidature) ->
    admincandidature_id = admincandidature.application.match(/\d+$/)[0]
    CandidaturesK.one(admincandidature_id).get().then((application) ->
      if($scope.binominal_link_id =="" && application.binomial_application == true)
          $scope.binominal_link_id = admincandidature.id
    )
  $scope.$watch("candidature", (newValue, oldValue) ->
    if(newValue)
      # console.log(newValue)
      candidat = newValue
      # cherche à faire un lien avec le binome
      if(candidat.binomial_application)
          binominal_split = candidat.binomial_application_with.split(" ")
          # cherche avec ce qu'a remplis le candidat (avec un peu de chance, le nom / prénom)
          for name in binominal_split
            critere = {search: name, application__campaign__is_current_setup:"true", application__application_completed:"true"}
            AdminCandidaturesK.getList(critere).then((candidatures) ->
              for candidature in candidatures
                setBinominalLinkCandidat(candidature)
            )
  )
  


)

.controller('CandidaturesConfigurationController', ($rootScope, $scope, APIV2K, CampaignsK, PromotionsK) ->
  $scope.configuration = []
  $scope.promotion = []

  $scope.now = () ->
    return new Date(Date.now())
  $scope.date = (date) ->
    return new Date(date)

  CampaignsK.getList({is_current_setup: "true"}).then((current_campaign) ->
    $scope.configuration = current_campaign[0]
    $scope.date_of_birth_max = new Date($scope.configuration.date_of_birth_max)
    $scope.interviews_publish_date = new Date($scope.configuration.interviews_publish_date)
    $scope.selected_publish_date = new Date($scope.configuration.selected_publish_date)
    $scope.candidature_date_end = new Date($scope.configuration.candidature_date_end)
    $scope.application_reminder_email_date = new Date($scope.configuration.application_reminder_email_date)
    # get promo infos
    promo_id = $scope.configuration.promotion.match(/\d+$/)[0]
    APIV2K.one("school/promotion/"+promo_id).get().then((promo) ->
        $scope.promo_name = promo.name
        $scope.promotion = promo
    )
  )
)


.controller('CandidaturesStatistiquesController', ($rootScope, $scope, Campaigns, 
  CandidaturesAnalytics, VimeoToken, Vimeo, Candidatures) ->
  # int countdown
  $scope.timer_countdown 
  $scope.year=null

   # CountDown
  $scope.refreshCountDown = () ->

      Campaigns.getList({is_current_setup: "true"}).then((current_campaign) ->
              # set campaign
              $scope.campaign = current_campaign[0]
              # set end of campagn
              dt = new Date($scope.campaign.candidature_date_end)
              $scope.candidature_date_end = dt

              # we take the opportunity to catch the year
              $scope.year = dt.getFullYear()
              # set timer
              $scope.timer_countdown = Math.round(
                    (new Date(dt).getTime() - new Date().getTime())/1000)
              $scope.$broadcast('timer-set-countdown', $scope.timer_countdown);      
      )

  $scope.refreshCountDown()
  
  # Analytics
  $scope.refreshAnalytics = () ->

      CandidaturesAnalytics.one().get().then((infos) ->

        $scope.analytics = infos[0]
      
      , (error) ->
        $scope.analytics = {"visits":0,"actions":0,"visitors":0,"visitsConverted":0}

      )    

  $scope.refreshAnalytics()

  # VIMEO
  VimeoToken.one().get().then((settings) ->
        Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
        $scope.refreshVimeoAnalytics()        
  )



  $scope.refreshVimeoAnalytics = () ->
    Vimeo.one("users/27279451/videos?fields=name,+description,+link&per_page=100&query=Inscription+-+"+$scope.year+"&query_fields=description").get().then((videos_infos) ->
  
        $scope.vimeoStatistics=videos_infos.data
    )

  # dossiers ouverts
  $scope.refreshCandidatures = () ->

      $scope.candidatures = Candidatures.getList( {'campaign__is_current_setup':'true',}).$object
      $scope.candidaturesComplete = Candidatures.getList( {'campaign__is_current_setup':'true', "application_completed": 'true', }).$object


  $scope.refreshCandidatures();





)