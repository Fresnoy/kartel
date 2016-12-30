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
    $scope.student = artist

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

.controller('ArtworkController', ($scope, $stateParams, $sce, Lightbox, Artworks, AmeRestangular,  Events, Collaborators, Partners) ->
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
    AmeRestangular.all("api_search/").get("",{"search": search, "flvfile": "true", "previewsize":"scr"}).then((ame_artwork) ->
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
    for artwork_uri in $scope.student.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)

.controller('ParentAccountController', ($rootScope, $scope) ->
  # init step in parent controller
)

.controller('AccountLoginController', ($rootScope, $scope) ->
    console.log("TODO")
)

.controller('AccountBarController', ($rootScope, $scope, $state, authManager) ->
    $scope.logout = () ->
      localStorage.removeItem("id_token")
      localStorage.removeItem("user_id")
      $rootScope.user = []
      authManager.unauthenticate()

      $state.go("candidature.account.login")
)

.controller("AccountConfirmationController", ($rootScope, $scope, Users) ->

    if localStorage.user_temp

        Users.one(localStorage.user_temp).get().then((response) ->
          $scope.user = response
          # $state.go('candidature.confirm-user')
        )
    else
      console.log("pas de user")
)

.controller('AccountResetPasswordController', ($rootScope, $scope) ->

)

.controller('AccountChangePasswordController', (
        $rootScope, $scope, $stateParams,
        $state, jwtHelper, RestAuth, Restangular
) ->

  $scope.user_id = false

  if($stateParams.token)

    tokenDecode = []
    try tokenDecode = jwtHelper.decodeToken($stateParams.token)
    catch e then tokenDecode.user_id = false

    route = $stateParams.route
    $scope.user_id = tokenDecode.user_id
    $scope.username = tokenDecode.username
    console.log(tokenDecode)

    $scope.submit = () ->
      password_infos =
        new_password1: $scope.new_password1
        new_password2: $scope.new_password2

      headers =
        Authorization: "JWT "+ $stateParams.token

      RestAuth.one().customPOST(password_infos, "password/change/", "", headers).then((response) ->
              delete localStorage.user_temp
              $state.go(route)
            , (response) ->
              $scope.form.error = "Erreur de changement de mot de passe"

      )
)

.controller('AccountPasswordAskController', ($rootScope, $scope, RestAuth) ->

  $scope.submit = () ->
      RestAuth.one().customPOST({email: $scope.email}, "password/reset/").then((response) ->
        $scope.form.success = response.success
      , (response) ->
        $scope.form.error = "Erreur d'envoie de l'email"

  )
)


.controller('ParentCandidatureController', ($rootScope, $scope,
            Restangular, Users, Candidatures, Artists, Galleries) ->
  # init step in parent controller
  $rootScope.step = []
  $rootScope.step.current = 0
  $rootScope.step.next = $rootScope.step.current + 1
  $rootScope.step.total = 12
  $rootScope.step.title = "welcom"

  #lang
  if localStorage.getItem("language")
    $rootScope.language = localStorage.getItem("language")

  $scope.setLang = (lang) ->
    localStorage.setItem("language", lang)
    $rootScope.language = localStorage.language

  #load user infos
  $rootScope.loadInfos = (scope) ->

    scope.user = []
    scope.user.profile = []
    scope.artist = []
    scope.candidature = []
    scope.candidature.administrative_galleries = []

    if(scope.candidature.length)
      return

    Users.one(localStorage.user_id).get().then((user) ->
      user.profile.birthdate = new Date(user.profile.birthdate)
      scope.user = user
      Candidatures.getList().then((candidatures) ->

        candidature = candidatures[0]
        scope.candidature = candidature

        #setup Galleries
        if(!candidature.administrative_galleries.length)
          gallery_infos =
            label: "Cursus : "+ candidature.current_year_application_count + " | " + $scope.user.username
            description: "Candidature's Gallery"



          Galleries.one().customPOST(gallery_infos).then((response) ->
            console.log("creation de la gallerie Cursus")
            scope.candidature.administrative_galleries.push(response.url)
            scope.candidature.save()
          )

        # get Artist
        matches = candidature.artist.match(/\d+$/)
        if matches
          artist_id = matches[0]
          # console.log(scope.candidature.plain())
          Artists.one(artist_id).get().then((artist) ->
              scope.artist = artist
          )
      )
    )

  # if localStorage.getItem('user_id')
    # $rootScope.loadInfos($rootScope)

)

.controller('LoginController', (
                                  $rootScope, $scope, Restangular, $state,
                                  Authentification, authManager, jwtHelper
                                ) ->

    $rootScope.step.current = 1
    $rootScope.step.title = "Login"

    if($scope.isAuthenticated)
      console.log("redirect")
      $state.go("candidature.resume")

    $scope.login = (form, params) ->
      if(form.$valid)
            Authentification.post(params).then((auth) ->
              authManager.authenticate()
              tokenDecode = jwtHelper.decodeToken(auth.token)
              localStorage.setItem('id_token', auth.token)
              localStorage.setItem('user_id', tokenDecode.user_id)
              # set header
              Restangular.setDefaultHeaders({Authorization: "JWT "+ auth.token})

              $state.go("candidature.resume")

            , ->
              #error
              console.log("Error login")
              params.error = "Error login"
              $scope.logout()
            )

    $scope.logout = () ->
      localStorage.removeItem("id_token")
      localStorage.removeItem("user_id")
      $rootScope.user = []
      authManager.unauthenticate()
)

.controller('ResumeAppController',($rootScope, $scope, $state, Users, Candidatures) ->

    console.log(Candidatures)
    Candidatures.getList().then((candidatures) ->
      console.log(candidatures)
    )


)
.controller('IdentificationController',($rootScope, $scope, $state, Registration, Users) ->

      $rootScope.step.current = 2
      $rootScope.step.title = "Identification"

      # init user form
      if(!$scope.user)
        $scope.user = {last_name: '', first_name: ''}

      # autogenerate username
      $scope.setUserName = (form, user) ->
        user.username = slug(user.first_name).toLowerCase().substr(0,1) + slug(user.last_name).toLowerCase()
        form.uUserName.$setTouched()
        console.log(form)
        $scope.isUniqueUserField(form.uUserName, user.username)

      if localStorage.user_temp
        Users.one(localStorage.user_temp).get().then((response) ->
            console.log(response)
            $scope.user = response
            # $state.go('candidature.confirm-user')
          )

      # create a new user
      $scope.create = (form, params) ->
        # console.log(params)
        form.disabled = true

        Registration.post(params).then((response) ->
          user =
              username:$scope.username
              first_name:$scope.first_name
              last_name:$scope.last_name
              email:$scope.email

          console.log(response)

          localStorage.setItem("user_temp", response)
          # change location
          $state.go('candidature.account.confirm-user')

        , (response) ->
          console.log(response)
          # user creation error
          # form.error = "Error Inscription " + JSON.stringify(response.error, null, '\t')
          form.error = "Error Inscription "
          form.disabled = false
        )
)


.controller('CivilStatusController', ($rootScope, $scope, $state, $filter, ISO3166, Restangular, Upload) ->

  if(!$scope.isAuthenticated)
    $state.go("candidature")

  $rootScope.loadInfos($rootScope)

  $scope.save = (model) ->

    # method 1 - copie du model et changement de valeurs sur des données "dirty"
    model_copy =  Restangular.copy(model)

    if model.profile.birthdate
      model_copy.profile.birthdate = $filter('date')(model.profile.birthdate, 'yyyy-MM-dd')

    if model_copy.profile.photo
      delete model_copy.profile.photo

    model_copy.save()


  # Birthdate minimum
  current_year = new Date().getFullYear()
  age_min = 18
  age_max = 35
  $scope.birthdateMax = new Date(current_year-age_min,11,31)
  $scope.birthdateMin = new Date(current_year-age_max,11,31)

  #country
  $scope.countries = ISO3166.countryToCode

)

.controller('ProfilePhotoController', ($rootScope, $scope, $state, $filter, ISO3166, Restangular, Upload) ->

  if(!$scope.isAuthenticated)
    $state.go("candidature")

  $rootScope.loadInfos($rootScope)

  #upload file
  $scope.upload_percentage = 0
  $scope.picture = (data) ->
      Upload.upload(
        {
          url: $scope.user.url,
          data: {
            "profile.photo": data
            #name: file.name
          }
          method: 'PATCH',
          headers: { 'Authorization': 'JWT ' + localStorage.id_token },
          #withCredentials: true
        }
      )
      .then((resp) ->
          console.log(resp)
          $scope.user.profile.photo = resp.data.profile.photo
        ,(resp) ->
          console.log('Error status: ' + resp.status);
        ,(evt) ->
          $scope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
      )
)



#cursus
.controller('CursusController', (
        $rootScope, $scope, $q, $state, $filter
        Users, Artists, Restangular, Candidatures, Galleries,
        ISO3166, Upload,
      ) ->

      if(!$scope.isAuthenticated)
        $state.go("candidature")

      $rootScope.loadInfos($rootScope)

      #cursus
      year = new Date().getFullYear();
      $scope.years = [];
      $scope.years.push (year-i) for i in [1..35]

      $scope.save = (model) ->



      $scope.cursus = {}
      $scope.cursus.items = []

      $scope.addItem = (item) ->
          item.push({
            medias:[]
            photo:"",
            name:""
          });

      $scope.removeItem = (items, num) ->
        items.splice(num,1)






)






# Candidature Form
.controller('CandidatureFormController', (
        $scope, $q, $state, $filter
        Users, Artists, Restangular, Candidatures,
        ISO3166, Upload,
  ) ->

  $scope.application = Candidatures
  $scope.user = Users
  $scope.user.profile = []
  $scope.artist = Artists

  $scope.create = (form) ->

    if(!form.$valid)
          console.log("Formulaire incomplet")
          console.log(form)
          return

    # change date after validation
    $scope.user.profile.birthdate = $filter('date')($scope.profile.birthdate, 'yyyy-MM-dd')

    # change other_language
    $scope.user.profile.other_language = $scope.user.profile.other_language.join(",")

    # cursus to txt
    $scope.user.profile.cursus = ""
    for item in $scope.cursus.items
      $scope.user.profile.cursus += item.year+ " - "+
       item.infos+"\r\n"

    Users.post($scope.user).then((recordedUser) ->

      console.log($scope.artist)
      console.log(recordedUser)
      $scope.artist.user = recordedUser.url

      console.log($scope.artist)

      Artists.post($scope.artist).then((recordedArtist) ->

            $scope.application.artist = recordedArtist.url

            Candidatures.post($scope.application).then((candidature) ->
              console.log("ok Candidature")
            )
        )
  )


    #update
  $scope.update = (user, form) ->
    return true


  if(localStorage.id_token)
    #user get
    Users.one(localStorage.user_id).get().then((user) ->

      if(user.username=="getoken")
        user.username = ""

      $scope.user = user


      #user profile get
      if (user.profile)
        matches = user.profile.match(/\d+$/)
        if matches
          profile_id = matches[0]
          Profiles.one(profile_id).get().then((profile) ->
            $scope.profile = profile
        )
        #artist get
      """
      Artists.getList().then((artists) ->
          for artist in artists
              if(parseInt(artist.user.match(/\d+$/)[0]) == $scope.user.id)
                $scope.artist = artist

            if($scope.artist == undefined)
              $scope.artist = Artists

      )"""

    )

  # Birthdate minimum
  current_year = new Date().getFullYear()
  age_min = 18
  age_max = 35
  $scope.birthdateMax = new Date(current_year-age_min,11,31)
  $scope.birthdateMin = new Date(current_year-age_max,11,31)

  #country
  $scope.countries = ISO3166.countryToCode

  #phone patterne
  $scope.phone_pattern = /^\+?\d{2}[-. ]?\d{9}$/

  #upload file
  $scope.upload_percentage = 0
  $scope.$watch('files', ->
        $scope.uploadMulty($scope.files);
  )
  $scope.uploadMulty = (files) ->
    if (files && files.length)
      for file in files
        if (!file.$error)
          $scope.upload(file)


  $scope.upload = (file, endpoint) ->

    Upload.upload(
      {
        url: endpoint,
        data: {
          "profile.photo": file
          #name: file.name
        }
        method: 'PATCH',
        headers: { 'Authorization': 'JWT ' + localStorage.id_token },
        #withCredentials: true
      }
    )
    .then((resp) ->
        #console.log('Success ' + resp.config.data.file.name + ' uploaded');
        console.log('Success');
        console.log(resp);
      ,(resp) ->
        console.log('Error status: ' + resp.status);
      ,(evt) ->
        #$scope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
        #console.log('progress: ' + $scope.upload_percentage + '% ' + evt.config.data.file.name);
    )

  #adresse
  $scope.paOptions = {
  	updateModel : true
  }
  $scope.paTrigger = {}
  $scope.paDetails = {}
  $scope.placesCallback = (place) ->
    console.log("hello")

  #languages
  $scope.LANGUAGES = languageMappingList


  #cursus
  year = new Date().getFullYear();
  $scope.years = [];
  $scope.years.push (year-i) for i in [1..age_max]

  $scope.cursus = {}
  $scope.cursus.items = []



  $scope.addItem = (item) ->
      item.push({
        medias:[]
        photo:"",
        name:""
      });

  $scope.removeItem = (items, num) ->
    items.splice(num,1)



  #first time application
  $scope.application.first_time = "true"


  #gallery
  $scope.artwork_galleries = []
  $scope.artwork_galleries.items = []
  $scope.artwork_galleries.medias = []

  #console.log($scope.artwork_galleries)
)
