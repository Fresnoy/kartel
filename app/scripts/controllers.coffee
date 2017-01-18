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
    for artwork_uri in $scope.student.artist.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)

.controller('CandidaturesController', ($rootScope, $scope, Candidatures, ArtistsV2, Users) ->
  # init
  $scope.candidatures = []

  Candidatures.getList({limit: 500}).then((candidatures) ->

    for candidature in candidatures
      artist_id = candidature.artist.match(/\d+$/)[0]
      if(candidature.application_completed)
        $scope.candidatures.push(candidature)
        ArtistsV2.one(artist_id).get().then((artist) ->
            current_cantidature = _.filter(candidatures, (c) -> return c.artist == artist.url)
            user_id = artist.user.match(/\d+$/)[0]
            artist.user = Users.one(user_id).get().$object
            current_cantidature[0].artist = artist
      )


  )

)

.controller('CandidatController', ($rootScope, $scope, $stateParams, Candidatures, ArtistsV2, Users, Galleries, Media, Lightbox) ->
  # init

  $scope.candidature = []
  $scope.artist = []
  $scope.user = []
  $scope.administrative_galleries = []
  $scope.artwork_galleries = []


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




  $scope.lightbox = (gallery, index) ->
    Lightbox.openModal(gallery, index)

  Candidatures.one().one($stateParams.id).get().then((candidature) ->
    $scope.candidature = candidature
    artist_id = candidature.artist.match(/\d+$/)[0]

    loadGalleries($scope.candidature.administrative_galleries)
    loadGalleries($scope.candidature.artwork_galleries)




    ArtistsV2.one(artist_id).get().then((artist) ->
        $scope.artist = artist
        user_id = artist.user.match(/\d+$/)[0]
        $scope.user = Users.one(user_id).get().$object

    )

    console.log($scope.candidature.administrative_galleries)


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


.controller('ParentCandidatureController', ($rootScope, $scope, $state,
            Restangular, RestangularV2,
            Users, Candidatures, ArtistsV2, Galleries, Media) ->
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
    # Artworks
    scope.candidature.artwork_galleries = []
    scope.artworks = []
    # Admin
    scope.candidature.administrative_galleries = []
    scope.cursus_gallery = []
    scope.cursus_gallery.id = []
    scope.cursus_gallery.url = []
    scope.cursus_gallery.media = []

    # if(scope.candidature.length)
    if(!scope.isAuthenticated)
      $state.go("candidature")

    Users.one(localStorage.user_id).get().then((user) ->

      scope.user = user
      Candidatures.getList().then((candidatures) ->
        # console.log("candidature")
        candidature = candidatures.pop()
        if(candidature.application_completed)
          $state.go("candidature.completed")
          return;

        scope.candidature = candidature

        #setup Galleries
        if(!candidature.administrative_galleries.length)
          # console.log("setup galleries")
          gallery_infos =
            label: "Cursus : "+ candidature.current_year_application_count + " | " + scope.user.username
            description: "Candidature's Gallery"

          Galleries.one().customPOST(gallery_infos).then((response) ->
            scope.candidature.administrative_galleries.push(response.url)
            scope.cursus_gallery.url = response.url
            scope.candidature.save()

            # Create one Media in the first admin gallery (cursus)
            medium_infos =
              gallery: response.url

            Media.one().customPOST(medium_infos).then((response_media) ->
              scope.cursus_gallery.media.push(response_media)
            )
          )
        # get Media administrative gallery
        else
          scope.cursus_gallery.url = scope.candidature.administrative_galleries[0]
          RestangularV2.oneUrl('assets/gallery', scope.cursus_gallery.url).get()
          .then((gall_response) ->
              for medium in gall_response.media
                  scope.cursus_gallery.media.push(
                    RestangularV2.oneUrl('assets/medium', medium).get().$object
                  )

          )

        if(scope.candidature.artwork_galleries)
          # get infos scope.artworks
          for gallery, index_gallery in scope.candidature.artwork_galleries
            # get object gallery
            RestangularV2.oneUrl('assets/gallery', gallery).get()
            .then((gall_response) ->
              # index not good

              for medium, index_medium in gall_response.media

                  RestangularV2.oneUrl('assets/medium', medium).get().then((response_medium) ->
                    find_medium = gall_response.media.indexOf(response_medium.url)
                    gall_response.media[find_medium] = response_medium

                  )

              find_gallery = scope.candidature.artwork_galleries.indexOf(gall_response.url)

              scope.artworks[find_gallery] = gall_response

            )

        # get Artist
        matches = candidature.artist.match(/\d+$/)
        if matches
          artist_id = matches[0]
          # console.log(scope.candidature.plain())
          ArtistsV2.one(artist_id).get().then((artist) ->
              scope.artist = artist
          )
      )
    )

  # if localStorage.getItem('user_id')
    # $rootScope.loadInfos($rootScope)

)

.controller('LoginController', (
                                  $rootScope, $scope, Restangular, RestangularV2, $state,
                                  Authentification, authManager, jwtHelper
                                ) ->

    $rootScope.step.current = 1
    $rootScope.step.title = "Login"

    if($scope.isAuthenticated)
      console.log("logged : resume candidature")
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
              RestangularV2.setDefaultHeaders({Authorization: "JWT "+ auth.token})

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
      $scope.current_candidature = candidatures[0]
      if($scope.current_candidature.application_completed)
        $state.go("candidature.finish")
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
        if (!user.first_name || !user.last_name)
          return

        user.username = slug(user.first_name).toLowerCase().substr(0,1) + slug(user.last_name).toLowerCase()
        form.uUserName.$setTouched()
        $scope.isUniqueUserField(form.uUserName, user.username)

      if localStorage.user_temp
        Users.one(localStorage.user_temp).get().then((response) ->
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


.controller('CivilStatusController', ($rootScope, $scope, $state, $filter, ISO3166, Restangular, RestangularV2, Upload) ->

  if(!$scope.isAuthenticated)
    $state.go("candidature")

  $rootScope.loadInfos($rootScope)

  $scope.save = (model) ->

    # console.log($scope.form)

    # method 1 - copie du model et changement de valeurs sur des données "dirty"
    model_copy =  RestangularV2.copy(model)

    if model_copy.profile.photo
      delete model_copy.profile.photo

    model_copy.save()



  # Birthdate minimum
  current_year = new Date().getFullYear()
  age_min = 18
  age_max = 35
  $scope.birthdateMax = $filter('date')(new Date(current_year-age_min,11,31), 'yyyy-MM-dd')
  $scope.birthdateMin = $filter('date')(new Date(current_year-age_max,11,31), 'yyyy-MM-dd')


  #country
  $scope.countries = ISO3166.countryToCode

)



.controller('CivilStatusAdressController', ($rootScope, $q,
            $scope, $state, $filter, ISO3166, Restangular, RestangularV2, Upload) ->


    $rootScope.loadInfos($rootScope)



    $scope.adress =
      street:''
      zip:''
      city:''

    $scope.$watch("user.profile.homeland_address", (newValue, oldValue) ->

      if(newValue!=oldValue)

        console.log(newValue)
        adress = newValue.split($scope.splitChar)

        $scope.adress.street = ''
        if(adress[0]!="undefined")
          $scope.adress.street = adress[0]

        $scope.adress.zip = ''
        if(adress[1]!="undefined")
          $scope.adress.zip = parseInt(adress[1])

        $scope.adress.city = ''
        if(adress[2]!="undefined")
          $scope.adress.city = adress[2]


    )

    $scope.splitChar = "\n\r"

    $scope.save = (model) ->
      # console.log($scope.form)
      model_copy =  RestangularV2.copy(model)

      if model.profile.birthdate
        model_copy.profile.birthdate = $filter('date')(model.profile.birthdate, 'yyyy-MM-dd')

      if model_copy.profile.photo
        delete model_copy.profile.photo

      # save homeland adress
      model_copy.profile.homeland_address = ""

      for item, value of $scope.adress
        if(value == undefined)
          value = ""
        model_copy.profile.homeland_address+= value + "" + $scope.splitChar
        # model.profile.homeland_address+= value + $scope.splitChar

        # console.log(value)

      # console.log(model_copy.profile.homeland_address)

      model_copy.save()


    # phone pattern
    $scope.phone_pattern = /^\+?\d{2}[-. ]?\d{9}$/


    # country
    $scope.countries = ISO3166.countryToCode


    #adresse
    $scope.paOptions = {
    	updateModel : true
    }
    $scope.paTrigger = {}
    $scope.paDetails = {}
    $scope.placesCallback = (place) ->
      console.log("hello")



)

.controller('CivilStatusLanguageController', ($rootScope, $scope, $state, $filter, ISO3166,
    Restangular, RestangularV2, Upload) ->

    $rootScope.loadInfos($rootScope)

    $scope.FAMILY_STATUS_CHOICES =
        "S":
          fr: "Seul(e)"
          en: "Single"
        "E":
          fr: "Fiancé(e)"
          en: "Engaged"
        "M":
          fr: "Marié(e)"
          en: "Married"
        "D":
          fr: "Divorcé(e)"
          en: "Divorced"
        "W":
          fr:"Veuf(ve)"
          en:"Widowed"
        "C":
          fr:"Union civile"
          en:"Civil Union"


    $scope.languageSelectOption =
      fr:"Selectionner une langue"
      en:"Select a Language"


    $scope.LANGUAGES = languageMappingList
    $scope.other_language = []
    $scope.splitChar = ","

    $scope.$watch("user.profile.other_language", (newValue, oldValue) ->
      if(newValue)
        $scope.other_language =   newValue.split($scope.splitChar)
    )

    $scope.removeLangue = (index) ->
      $scope.other_language.splice(index,1)
      $scope.updateLanguages()


    $scope.updateLanguages = () ->
      $scope.user.profile.other_language = $scope.other_language.join($scope.splitChar)
      $scope.save()


    $scope.save = (model) ->

        user_copy = RestangularV2.copy($scope.user)

        if user_copy.profile.photo
          delete user_copy.profile.photo

        if user_copy.profile.birthdate
          user_copy.profile.birthdate = $filter('date')(user_copy.profile.birthdate, 'yyyy-MM-dd')

        user_copy.save()

)
.controller('ProfilePhotoController', ($rootScope, $scope, $state, Restangular, Upload) ->

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
        Users, ArtistsV2, Restangular, RestangularV2, Candidatures, Media, Galleries,
        ISO3166, Upload,
      ) ->

      if(!$scope.isAuthenticated)
        $state.go("candidature")

      $rootScope.loadInfos($rootScope)


      $scope.state =
         selected: undefined
      #cursus
      year = new Date().getFullYear();
      $scope.years = []
      $scope.years.push (year-i) for i in [1..35]

      $scope.save = (model) ->
        console.log($scope.form)
        # save medium
        model_copy = RestangularV2.copy(model)

        if model_copy.picture
          delete model_copy.picture

        model_copy.save()

        $scope.state.selected = model.position
        # save user profile cursus
        cursus = ""
        for item in $scope.cursus_gallery.media
          cursus += item.label + " " + item.description
          cursus += "\n"

        $scope.user.profile.cursus = cursus
        user_copy = RestangularV2.copy($scope.user)

        if user_copy.profile.birthdate
          user_copy.profile.birthdate = $filter('date')(user_copy.profile.birthdate, 'yyyy-MM-dd')


        if user_copy.profile.photo
          delete user_copy.profile.photo

        user_copy.save()



      #upload file
      $scope.upload_percentage = 0
      $scope.upload = (model, field, data ) ->
          infos =
            url: model.url,
            data: {}
            method: 'PATCH',
            headers: { 'Authorization': 'JWT ' + localStorage.id_token },
            #withCredentials: true
          infos.data[field] = data

          Upload.upload(infos)
          .then((resp) ->
              model[field] = resp.data[field]
            ,(resp) ->
              console.log('Error status: ' + resp.status);
            ,(evt) ->
              $scope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
          )

      $scope.addItem = (gallery) ->

        medium_infos =
          gallery: gallery.url

        Media.one().customPOST(medium_infos).then((response_media) ->
          gallery.media.push(response_media)
          $scope.state.selected = 1
        )

      $scope.removeItem = (media, index) ->
        item = media[index]
        item.remove().then((response) ->
            media.splice(index,1)
        )

)


# media
.controller('MediaController', (
        $rootScope, $scope, $q, $state, $filter
        Users, ArtistsV2, Restangular, RestangularV2, Candidatures, Media, Galleries,
        ISO3166, Upload,
      ) ->


    if(!$scope.isAuthenticated)
      $state.go("candidature")


    $rootScope.loadInfos($rootScope)

    $scope.state =
         selected: undefined


    $scope.addArtwork = () ->

        gallery_infos =
          label: $scope.candidature.current_year_application_count+" | "
          description: " Desciption de l'oeuvre "

        Galleries.one().customPOST(gallery_infos).then((response) ->
          $scope.candidature.artwork_galleries.push(response.url)
          $scope.candidature.save()

          $scope.artworks.push(response)

          $scope.state.selected = response.id


        )

    $scope.removeArtwork = (model, index) ->
        item = model[index]
        url = item.url
        item.remove().then((response) ->
            find = $scope.candidature.artwork_galleries.indexOf(url)

            $scope.candidature.artwork_galleries.splice(find,1)
            model.splice(index, 1)

            $scope.candidature.save()


        )

    $scope.saveGalleryInfos = (gallery) ->
      gallery.save()


    # medium
    $scope.addMediumLink = (gallery) ->
      medium_infos =
        gallery: gallery.url

      index_medium = gallery.media.length
      gallery.media[index_medium] = Media.one().customPOST(medium_infos).$object



    $scope.removeMedium = (medium, gallery, index) ->
      medium.remove().then((response) ->
          gallery.media.splice(index,1)
      )


    $scope.uploadFiles = (files, gallery) ->
      if (files && files.length)
        for file in files
            $scope.upload(file, "photo", gallery)

    $scope.upload = (data, field, gallery) ->

            # Create one Media in the first admin gallery (cursus)
          medium_infos =
            gallery: gallery.url

          if(!data.type.match('image.*'))
            console.log("non image")
            return

          # create medium
          Media.one().customPOST(medium_infos).then((response_media) ->

            infos =
              url: response_media.url,
              data: {}
              method: 'PATCH',
              headers: { 'Authorization': 'JWT ' + localStorage.id_token },
              #withCredentials: true
            infos.data.picture = data

            index_medium = gallery.media.length
            gallery.media[index_medium] = response_media

            Upload.upload(infos)
            .then((resp) ->
                gallery.media[index_medium] = RestangularV2.oneUrl('assets/medium', infos.url).get().$object

              ,(resp) ->
                console.log('Error status: ' + resp.status);
              ,(evt) ->
                $scope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
            )
        )

)


.controller('InterviewController', (
        $rootScope, $scope, $q, $state, $filter
        Users, ArtistsV2, Restangular, Candidatures, Media, Galleries,
        ISO3166, Upload,
      ) ->

    if(!$scope.isAuthenticated)
      $state.go("candidature")

    $rootScope.loadInfos($rootScope)

    $scope.INTERVIEW_TYPES = [
          "Skype"
          "Hangouts"
          "FaceTime"
          "OOVOO"
          "Facebook"
          "ApperIn"
          "Spark Hire"
          "Other"
    ]
)





.controller('MessageController', (
        $rootScope, $scope, $q, $state, $filter
        Users, ArtistsV2, Restangular, Candidatures, Media, Galleries,
        ISO3166, Upload,
      ) ->

    if(!$scope.isAuthenticated)
      $state.go("candidature")


    $rootScope.loadInfos($rootScope)
)


.controller('ConfirmationController', (
        $rootScope, $scope, $state, Candidatures,
      ) ->

    if(!$scope.isAuthenticated)
      $state.go("candidature")


    $rootScope.loadInfos($rootScope)

    $scope.validation = false


    $scope.valideCandidature = (candidature) ->

      candidature.application_completed = true
      candidature.save()

      $state.go("candidature.completed")



)


# Candidature Form
.controller('CandidatureFormController', (
        $scope, $q, $state, $filter
        Users, ArtistsV2, Restangular, Candidatures,
        ISO3166, Upload,
  ) ->

  $scope.application = Candidatures
  $scope.user = Users
  $scope.user.profile = []
  $scope.artist = []

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

      ArtistsV2.post($scope.artist).then((recordedArtist) ->

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
