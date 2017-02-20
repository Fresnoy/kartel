# -*- tab-width: 2 -*-
"use strict"

angular.module('candidature.controllers', ['memoire.services', 'candidature.services'])

.controller('ParentAccountController', ($rootScope, $scope) ->
  # init step in parent controller
)

.controller('AccountLoginController', ($rootScope, $scope) ->
    console.log("TODO")
)

.controller("AccountConfirmationController", ($rootScope, $stateParams, $scope, Users) ->

)

.controller('AccountResetPasswordController', ($rootScope, $scope) ->

)

.controller('AccountChangePasswordController', (
        $rootScope, $scope, $stateParams, $http,
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

.controller('LoginController', (
  $rootScope, $scope, RestangularV2, $state, $http, Login,
  Authentification, authManager, jwtHelper
                                ) ->

    # localStorage.clear()
    # console.log(localStorage)

    $rootScope.step.current = "02"
    $rootScope.step.title = "Login"
    $rootScope.current_display_screen = $rootScope.screen.login

    $scope.vm =
      username:""
      email:""
      password:""

    if($scope.isAuthenticated)
      console.log("logged : resume candidature")
      $state.go("candidature.option")

    $scope.login = (form, params) ->

      Login.post(params, [headers={}])
      .then((auth) ->
            localStorage.setItem('token', auth.token)
            # set header
            $http.defaults.headers.common.Authorization = "JWT "+ localStorage.getItem('token')
            authManager.authenticate()
            $state.go("candidature.option")
          , () ->
            console.log("error")
            params.error = "Error login"
            $scope.logout()
     )

    $scope.logout = () ->
      Authentification.one("logout/").post().then((auth) ->
          localStorage.removeItem("token")
          delete $http.defaults.headers.common.Authorization
          $rootScope.user = $scope.user = []
          authManager.unauthenticate()
      )

)

.controller('CreateAccountController',($rootScope, $scope, $state, Registration, RestangularV2, Users) ->
      # inscription

      $scope.user_created = false
      $scope.edit_email = false
      $scope.send_email = 2

      $rootScope.step.current = "02"
      $rootScope.step.title = "Identification"
      $rootScope.current_display_screen = $rootScope.screen.create_user

      # init user form
      if(!$scope.user)
        $scope.user =
            last_name: ''
            first_name: ''
            email: ''

      # autogenerate username
      $scope.setUserName = (form, user) ->
        console.log(form)
        if (!user.first_name || !user.last_name)
          return
        user.username = slug(user.first_name).toLowerCase().substr(0,1) + slug(user.last_name).toLowerCase()
        form.uUserName.$setTouched()

        # $scope.isUniqueUserField(form.uUserName, user.username)

      # create a new user
      $scope.create = (form, params) ->
        console.log(params)

        Registration.post(params).then((response) ->
          $scope.user_created = true
        , (response) ->
          form.error = response.data

        )

      $scope.update_infos = (form, params) ->
        console.log(params)
        form.$setSubmitted()
        RestangularV2.all('people/user/resend_activation_email').post(params).then((response) ->
          $scope.send_email--
        , (response) ->
          console.log(form)
          console.log(response)
          form.$error = response.data

        )

)


.controller('ParentCandidatureController', ($rootScope, $scope, $state, jwtHelper, $q,
            Restangular, RestangularV2, Vimeo, Authentification, $http, cfpLoadingBar, authManager,
            Users, Candidatures, ArtistsV2, Galleries, Media, Upload) ->

  $rootScope.__cache = new Date().getTime()

  # Media
  $rootScope.screen = []
  $rootScope.screen =
      home:
        image:"renaud_duval_sealine_excroissance_i.jpg"
        copyright:"Abtin Sarabi 2017"
        position: {x:0,y:0}
      create_user:
        image:"junkai-chen_correspondances_2016_3.jpg"
        copyright:"Abtin Sarabi 2017"
        position: {x:0,y:0}
      login:
        image:"clea-coudsy40.jpg"
        copyright:"Abtin Sarabi 2017"
        position: {x:0,y:0}
      option:
        image:"abtin-sarabi_si-l’homme-a-temps-avait-ouvert-ses-yeux-egares_2016_1.jpg"
        copyright:"Abtin Sarabi 2017"
        position: {x:0,y:0}
      personnal:
        image:"baptiste-rabichon_diamonds_2016"
        copyright:"Abtin Sarabi 2017"
        position: {x:0,y:0}


  $rootScope.current_display_screen = $rootScope.screen.home

  # init step in parent controller
  $rootScope.step = []
  $rootScope.step.current = "00"
  $rootScope.step.total = 12
  $rootScope.step.title = "Welcome"

  # navigation
  $rootScope.navigation_inter_page = 0

  # Dates
  $rootScope.current_year = new Date().getFullYear()
  $rootScope.age_min = 18
  $rootScope.age_max = 36


  # write data var
  $rootScope.writingData = false

  # lang
  if localStorage.getItem("language")
    $rootScope.language = localStorage.getItem("language")

  $scope.setLang = (lang) ->
    localStorage.setItem("language", lang)
    $rootScope.language = localStorage.language


  # logout
  $rootScope.logout = () ->
    Authentification.one("logout/").post().then((auth) ->
        localStorage.removeItem("token")
        $rootScope.user = []
        delete $http.defaults.headers.common.Authorization
        authManager.unauthenticate()
        $state.go("candidature.account.login")
    )


  $rootScope.$on('data:write', (event, data) ->
    $rootScope.writingData = true

  )
  $rootScope.$on('data:read', (event, data) ->
    $rootScope.writingData = false

  )


  createNewGallery = (scope, model, array_galleries_name, gallerie_label, gallerie_description, return_var) ->
      gallery_infos =
        label: gallerie_label
        description: gallerie_description
        # "Candidature's Gallery"
      Galleries.one().customPOST(gallery_infos).then((response_gallerie) ->
        # scope.candidature.administrative_galleries.push(response.url)
        if(model[array_galleries_name] instanceof Array)
          model[array_galleries_name].push(response_gallerie.url)
        else
          model[array_galleries_name] = response_gallerie.url
        return_var = response_gallerie
        infos = {}
        infos[array_galleries_name] =  model[array_galleries_name]

        model.patch(infos)
        # model.save()
      )

  getGalleryWithMedia = (gallery_url, return_var) ->
      RestangularV2.oneUrl('assets/gallery', gallery_url).get()
      .then((gall_response) ->
          return_var.url = gall_response.url
          for medium in gall_response.media
              RestangularV2.oneUrl('assets/medium', medium).get().then((response_medium) ->
                  find_medium = gall_response.media.indexOf(response_medium.url)
                  return_var.media[find_medium] = response_medium
              )

      )

  $rootScope.upload = (data, model, field) ->

      infos =
        url: model.url,
        data: {}
        method: 'PATCH',
        headers: { 'Authorization': 'JWT ' + localStorage.token },
        #withCredentials: true

      infos.data[field] = data
      Upload.upload(infos)
      .then((resp) ->
          model[field] = resp.data[field]
        ,(resp) ->
          console.log('Error status: ' + resp.status);
        ,(evt) ->
          $rootScope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
      )

  #load user infos
  $rootScope.loadInfos = (scope) ->

    scope.user = []
    scope.user.profile = []
    scope.artist = []
    scope.candidature = []

    scope.artworks = []
    # Admin
    scope.candidature.cursus_justifications = []
    scope.cursus_justifications = []
    scope.cursus_justifications.id = []
    scope.cursus_justifications.url = []
    scope.cursus_justifications.media = []

    # if(scope.candidature.length)
    if(!scope.isAuthenticated)
      $state.go("candidature.account.login")

    user_id = jwtHelper.decodeToken(localStorage.getItem('token')).user_id
    Users.one(user_id).get().then((user) ->
      scope.user = user

      Candidatures.getList().then((candidatures) ->
        console.log(candidatures.length)
        if (candidatures.length >= 2)
          $state.go("candidature.error_admin_user")

        candidature = candidatures[candidatures.length-1]
        scope.candidature = candidature
        if(candidature.application_completed)
          $state.go("candidature.completed")
          return

        if(scope.candidature.cursus_justifications)
          getGalleryWithMedia(scope.candidature.cursus_justifications, scope.cursus_justifications)
        else
          #
          createNewGallery(
            scope,
            scope.candidature,
            "cursus_justifications",
            "Cursus",
            "Candidatures de "+ user.last_name + " " + user.first_name + " | " + candidature.current_year_application_count,
            scope.cursus_justifications
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
    , (userInfos_error) ->
      console.log("error user infos")
      $state.go("candidature.error")
    )



)



.controller('PersonnalInfosController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

  if(!$scope.isAuthenticated)
    $state.go("candidature")

  console.log($state.current)

  $rootScope.loadInfos($rootScope)

  $scope.save = (model) ->
    model_copy =  RestangularV2.copy(model)
    if model_copy.profile.photo
      delete model_copy.profile.photo

    model_copy.save()


  $scope.birthdateMin = $filter('date')(new Date($rootScope.current_year-$rootScope.age_min,11,31), 'yyyy-MM-dd')
  $scope.birthdateMax = $filter('date')(new Date($rootScope.current_year-$rootScope.age_max+1,1,1), 'yyyy-MM-dd')

  # Gender
  $scope.gender =
    M: fr: "Homme", en: "Male"
    F: fr: "Femme", en: "Female"
    T: fr: "Transgenre", en: "Transgender"
    O: fr: "Autre", en: "Other"

  #country
  $scope.countries = ISO3166.countryToCode

  # nationality
  $scope.nationality = []
  $scope.splitChar = ", "

  $scope.$watch("user.profile.nationality", (newValue, oldValue) ->
    if(newValue)

      $scope.nationality = newValue.split($scope.splitChar)

  )
  # phone pattern
  # $scope.phone_pattern = /^\+?\d{2,5}[-. ]?\d{9,15}$/
  $scope.phone_pattern = /^\+?[0-9-]{2,5}[-. ]?\d{5,12}$/
  $scope.$watch("user.profile.homeland_phone", (newValue, oldValue) ->
    if(newValue)
      $scope.phone_number = newValue.split(" ").pop()
      $scope.phone_country = newValue.split(" ").shift().substr(1)
      if($scope.form2.uHomelandPhone.$valid)
        $scope.save($scope.user)
  )

  $scope.languageSelectOption =
    fr:"Selectionner une langue"
    en:"Select a language"


  $scope.LANGUAGES = languageMappingList
  $scope.other_language = []

  $scope.$watch("user.profile.other_language", (newValue, oldValue) ->
    if(newValue)
      $scope.other_language =   newValue.split($scope.splitChar)
  )


  # justif photo
  $scope.photo_justification_file = null

  $scope.uploadFile = (data, model, field, type) ->
    $rootScope.upload(data, model, field)


  # specific upload Photo
  $scope.uploadPhoto = (data, model, form) ->

    infos =
      url: model.url,
      data: {
        'profile.photo' : data
      }
      method: 'PATCH',
      headers: { 'Authorization': 'JWT ' + localStorage.token },
      #withCredentials: true

    Upload.upload(infos)
    .then((resp) ->
        model.profile.photo = resp.data.profile.photo
      ,(resp) ->
        model.profile.photo = ""
      ,(evt) ->
        $rootScope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
    )
)


#cursus
.controller('CursusController', (
        $rootScope, $scope, $q, $state, $filter,
        Users, ArtistsV2, Restangular, RestangularV2, Candidatures, Media, Galleries,
        ISO3166, Upload,
      ) ->

      if(!$scope.isAuthenticated)
        $state.go("candidature")

      $rootScope.loadInfos($rootScope)

      $scope.state =
         selected: undefined
      #cursus
      year = new Date().getFullYear()
      $scope.years = []
      $scope.years.push (year-i) for i in [1..35]

      #patch Medium
      $scope.uploadFile = (data, model ) ->

          field = "picture"
          if (data.type.match("image.*"))
            field = "picture"
          if (data.type.match("pdf"))
            field = "file"

          $rootScope.upload(data, model, field)


      # ITEM ADD
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
        $rootScope, $scope, $q, $state, $filter, $sce,
        Users, ArtistsV2, Restangular, RestangularV2, Candidatures, Media, Galleries,
        ISO3166, Upload, VimeoToken, Vimeo
      ) ->

    $rootScope.loadInfos($rootScope)

    $scope.trustSrc = (src) ->
      return $sce.trustAsResourceUrl(src);


    $scope.deleteVimeoVideo = (idVimeo, model, field) ->
      # get Vimeo token api
      VimeoToken.one().get().then((settings) ->
          Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
          video_uri = "videos/"+idVimeo
          Vimeo.one(video_uri).remove().then((video_infos) ->
            console.log("video_infos")
            console.log(video_infos)
            model[field] = ""
            patch_infos = {}
            model[field] = ""
            patch_infos[field] = model[field]
            model.patch(patch_infos)

          )
      )


    $scope.uploadVimeo = (data, model, field) ->

      if (!data)
        return

      # get Vimeo token api
      VimeoToken.one().get().then((settings) ->
          console.log("vimeoUpload")
          # localStorage.setItem('vimeo_upload_token',settings.token)
          Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
          # console.log(Vimeo)
          # connect to vimeo api
          Vimeo.one("me").get().then((account_infos) ->
              # console.log(account_infos)
              console.log((account_infos.data.upload_quota.space.free / 1073741824).toFixed(3) + " GB")
              upload_settings =
                type: "streaming"
              # get an upload ticket
              account_infos.data.customPOST(upload_settings,"videos").then((ticket) ->
                    # console.log("ticket")
                    # console.log(ticket)

                    # http method because Vimeo crash when multipart upload
                    #  send no Authorization
                    upload_config =
                      url: ticket.data.upload_link_secure
                      headers:
                        'Content-type': data.type
                        'Authorization': undefined
                      data: data
                      method: 'PUT'
                    Upload.http(upload_config)
                    .then((resp) ->
                        console.log("Successful upload VIMEO")
                        # Complete the upload : complete_uri remove
                        Vimeo.one(ticket.data.complete_uri).remove().then((remove) ->
                          console.log("Ok Vimeo now video is complete")
                          # get video id
                          location = remove.headers('Location')
                          video_id = location.split('/')[2]
                          # save the media link
                          patch_infos = {}
                          model[field] = "https://player.vimeo.com/video/"+video_id
                          patch_infos[field] = model[field]
                          model.patch(patch_infos)
                          # rename the video
                          video_info =
                            name: data.name
                            description: "Inscription - " + $scope.candidature.current_year_application_count + " | " + $scope.user.last_name + " - " + $scope.user.first_name

                          Vimeo.one(location).patch(video_info).then((patch_response) ->
                            # console.log("Video set Title and description")
                            # put video in album 4370111 (candidature 2017)
                            album_id = 4370111
                            Vimeo.one(account_infos.data.uri).customPUT({}, "albums/"+album_id+"/videos/"+video_id).then((response_album) ->
                                # console.log("Video in specific album : " + album_id)
                            )
                          )
                        )
                      , (error)->
                        console.log("ERROR  upload VIMEO")
                        console.log(error)
                      , (evt) ->
                        $scope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total)

                    )
                  )
            )

        , ->
          # error
          console.log("vimeoUploadError")
      )

    $scope.uploadFile = (data, model, field) ->
      $rootScope.upload(data, model, field)

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
