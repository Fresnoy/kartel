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

  $scope.emailSended = false;
  $scope.submit = () ->
      RestAuth.one().customPOST({email: $scope.email}, "password/reset/").then((response) ->
        $scope.emailSended = true;
      , (response) ->
        $scope.form.error = "Erreur d'envoie de l'email"

  )
)

.controller('LoginController', (
  $rootScope, $scope, RestangularV2, $state, $http, Login,
  Logout, authManager, jwtHelper
                                ) ->

    # localStorage.clear()
    # console.log(localStorage)

    $rootScope.step.current = "07"
    $rootScope.step.title = "Login"
    $rootScope.current_display_screen = $rootScope.screen.login

    $scope.vm =
      username:""
      email:""
      password:""

    if($scope.isAuthenticated)
      console.log("logged : resume candidature")
      $state.go("candidature.option")

    delete $http.defaults.headers.common.Authorization

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
      Logout.post([], [headers={}]).then((auth) ->
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

      $rootScope.step.current = "04"
      $rootScope.step.title = ""
      $rootScope.current_display_screen = $rootScope.screen.create_user

      $scope.$watch('navigation_inter_page', (value) ->
          if(value == 0)
              $rootScope.current_display_screen = $rootScope.screen.personnal
              $rootScope.step.title = ""
              $rootScope.step.current = "04"
          if(value == 1)
              $rootScope.current_display_screen = $rootScope.screen.personnal2
              $rootScope.step.current = "05"
              $rootScope.step.title = ""
      )



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
          $scope.navigation_inter_page = 1
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
            Restangular, RestangularV2, Vimeo, Logout, $http, cfpLoadingBar, authManager, ISO3166,
            Users, Candidatures, ArtistsV2, Galleries, Media, Upload) ->

  $rootScope.__cache = new Date().getTime()

  # Media
  $rootScope.screen = []
  $rootScope.screen =
      home:
        image:"renaud_duval_sealine_excroissance_i.jpg"
        copyright:"Renaud Duval 2017"
        position: {x:0,y:0}
      create_user:
        image:"junkai-chen_correspondances_2016_3.jpg"
        copyright:"Junkai Chen 2017"
        position: {x:0,y:0}
      login:
        image:"clea-coudsy40.jpg"
        copyright:"Cléa Coudsy 2017"
        position: {x:0,y:0}
      option:
        image:"abtin-sarabi_si-l-homme-a-temps-avait-ouvert-ses-yeux-egares_2016_1.jpg"
        copyright:"Abtin Sarabi 2017"
        position: {x:0,y:0}

      personnal:
        image:"chia-wei-hsu_ecriture-divine_2016_2.jpg"
        copyright:"Baptiste Rabichon 2017"
        position: {x:"-0px",y:"33%"}
      personnal2:
        image:"chia-wei-hsu_ecriture-divine_2016_2.jpg"
        copyright:"Baptiste Rabichon 2017"
        position: {x:"-50px",y:"33%"}
      personnal3:
        image:"chia-wei-hsu_ecriture-divine_2016_2.jpg"
        copyright:"Baptiste Rabichon 2017"
        position: {x:"-100px",y:"33%"}
      personnal4:
        image:"chia-wei-hsu_ecriture-divine_2016_2.jpg"
        copyright:"Baptiste Rabichon 2017"
        position: {x:"-150px",y:"33%"}
      cursus:
        image:"victor-vaysse_while-true_2016_2.jpg"
        copyright:""
        position: {x:0,y:0}
      cursus2:
        image:"kate-krolle_on-porte-nos-coeurs_2014_10.jpg"
        copyright:""
        position: {x:0,y:0}
      cursus3:
        image:"baptiste-rabichon_diamonds_2016.jpg"
        copyright:""
        position: {x:0,y:0}
      docs:
        image:"leonard-martin_yoknapatawpha_2016_2.jpg"
        copyright:""
        position: {x:0,y:0}
      docs2:
        image:"gaetan-robillard_l-oeil-du-gymnote_2012_01.jpg"
        copyright:""
        position: {x:0,y:0}
      docs3:
        image:"fabien-zocco_l'entreprise-de-de-deconstruction-theotechnique_2016_2.jpg"
        copyright:""
        position: {x:0,y:0}
      docs4:
        image:"david-ayoun_deha-vani_2014_3.jpg"
        copyright:""
        position: {x:0,y:0}
      message:
        image:"fabien_zocco_mind-body_problem_2015_01.jpg"
        copyright:""
        position: {x:0,y:0}
      message2:
        image:"junkai-chen_correspondances_2016_3.jpg"
        copyright:""
        position: {x:0,y:0}
      message3:
        image:"kate-krolle_on-porte-nos-coeurs_2014_10.jpg"
        copyright:""
        position: {x:0,y:0}
      final:
        image:"gaetan-robillard_l-oeil-du-gymnote_2012_01.jpg"
        copyright:""
        position: {x:0,y:0}
      final2:
        image:"alexandru-petru-badelita_i-made-you-i-kill-you_2016.jpg"
        copyright:""
        position: {x:0,y:0}
      final3:
        image:"regina_demina_l-avalanche_2015_09.jpg"
        copyright:""
        position: {x:0,y:0}



  if(!$rootScope.current_display_screen)
    $rootScope.current_display_screen = $rootScope.screen.home

  # init step in parent controller
  $rootScope.step = []
  $rootScope.step.current = "00"
  $rootScope.step.total = 19
  $rootScope.step.title = "Welcome"

  # navigation
  $rootScope.navigation_inter_page = 0
  $rootScope.display_help = false
  $scope.show_help = () ->
    console.log("Please Help !")
    $rootScope.display_help = !$rootScope.display_help

  # Dates
  $rootScope.current_year = new Date().getFullYear()
  $rootScope.age_min = 18
  $rootScope.age_max = 36

  # phone
  $rootScope.phone_pattern = /^\+?[0-9-]{2,5}[-. ]?\d{5,12}$/


  # write data var
  $rootScope.writingData = false

  # lang
  if localStorage.getItem("language")
    $rootScope.language = localStorage.getItem("language")

  $scope.setLang = (lang) ->
    localStorage.setItem("language", lang)
    $rootScope.language = localStorage.language

  # countries
  $rootScope.getCountrie = (code) ->
    return _.invert(ISO3166.countryToCode)[code]


  # logout
  $rootScope.logout = () ->
    Logout.post({},{},{}).then((auth) ->
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
    setTimeout ( ->
      $rootScope.writingData = false
    ), 100
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


.controller('IntroController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

        $scope.$watch('navigation_inter_page', (value) ->
            if(value == 0)
                $rootScope.current_display_screen = $rootScope.screen.personnal
                $rootScope.step.title = "Bienvenue"
                $rootScope.step.current = "01"
            if(value == 1)
                $rootScope.current_display_screen = $rootScope.screen.personnal2
                $rootScope.step.current = "02"
                $rootScope.step.title = ""
            if(value == 2)
                $rootScope.current_display_screen = $rootScope.screen.personnal2
                $rootScope.step.current = "03"
        )

)



.controller('PersonnalInfosController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

  if(!$scope.isAuthenticated)
    $state.go("candidature")

  console.log($state.current)

  $rootScope.loadInfos($rootScope)
  $rootScope.step.current = "03"
  $rootScope.step.title = "Informations personnelles"

  $rootScope.current_display_screen = $rootScope.screen.personnal

  $scope.$watch('navigation_inter_page', (value) ->
      if(value == 0)
          $rootScope.current_display_screen = $rootScope.screen.personnal
          $rootScope.step.current = "03"
      if(value == 1)
          $rootScope.current_display_screen = $rootScope.screen.personnal2
          $rootScope.step.current = "04"
      if(value == 2)
          $rootScope.current_display_screen = $rootScope.screen.personnal3
          $rootScope.step.current = "05"
      if(value == 3)
          $rootScope.current_display_screen = $rootScope.screen.personnal4
          $rootScope.step.current = "06"
  )




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

  $scope.$watch("user.profile.homeland_phone", (newValue, oldValue) ->
    if(newValue)
      $scope.phone_number = newValue.split(" ").pop()
      $scope.phone_country = newValue.split(" ").shift().substr(1)
      if($scope.form2.uHomelandPhone.$valid)
        $scope.save($scope.user)
  )

  $scope.languageSelectOption =
    fr:"Sélectionner une langue"
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

      $rootScope.current_display_screen = $rootScope.screen.cursus
      $rootScope.step.title = "Cursus"

      $scope.$watch('navigation_inter_page', (value) ->
          if(value == 0)
              $rootScope.current_display_screen = $rootScope.screen.cursus
              $rootScope.step.current = "07"

          if(value == 1)
              $rootScope.current_display_screen = $rootScope.screen.cursus2
              $rootScope.step.current = "08"
              $rootScope.step.title = "Parcours"
          if(value == 2)
              $rootScope.current_display_screen = $rootScope.screen.cursus3
              $rootScope.step.current = "09"
      )

      $scope.state =
         selected: undefined
      #cursus
      year = new Date().getFullYear()
      $scope.years = []
      $scope.years.push (year-i) for i in [1..35]
      #
      $scope.uploadFileExp = (data, model, field) ->
        $rootScope.upload(data, model, field)

      #patch Medium
      $scope.uploadFile = (data, model) ->

          field = "picture"
          if (data.type.match("image.*"))
            field = "picture"
          if (data.type.match("pdf"))
            field = "file"

          medium_infos =
            gallery: model.url
          Media.one().customPOST(medium_infos).then((response_media) ->
            model.media.push(response_media)
            $rootScope.upload(data, response_media, field)
          )


      # ITEM ADD
      $scope.addItem = (gallery) ->
        medium_infos =
          gallery: gallery.url
        Media.one().customPOST(medium_infos).then((response_media) ->
          gallery.media.push(response_media)
        )
      $scope.removeItem = (media, index) ->
        item = media[index]
        item.remove().then((response) ->
            media.splice(index,1)
        )

)



# media
.controller('MediaController', (
        $rootScope, $scope, $q, $state, $filter, $sce, $http,
        Users, ArtistsV2, Restangular, RestangularV2, Candidatures, Media, Galleries,
        ISO3166, Upload, VimeoToken, Vimeo
      ) ->

    $rootScope.loadInfos($rootScope)

    $scope.trustSrc = (src) ->
      return $sce.trustAsResourceUrl(src);


    $scope.honor = false
    $rootScope.step.title = "Documents"

    $scope.$watch('navigation_inter_page', (value) ->
        if(value == 0)
            $rootScope.current_display_screen = $rootScope.screen.docs
            $rootScope.step.current = "10"
            $rootScope.step.title = "Documents"

        if(value == 1)
            $rootScope.current_display_screen = $rootScope.screen.docs2
            $rootScope.step.current = "11"
            $rootScope.step.title = "Projets"
        if(value == 2)
            $rootScope.current_display_screen = $rootScope.screen.docs3
            $rootScope.step.current = "12"
            $rootScope.step.title = "Projets"
        if(value == 2)
            $rootScope.current_display_screen = $rootScope.screen.docs4
            $rootScope.step.current = "13"
            $rootScope.step.title = "œuvres"
    )

    $scope._isAvailableVideo = false
    $scope.isAvailableVideo = (videoUri) ->
      if(!videoUri)
        $scope._isAvailableVideo = false
        return
      if(videoUri.indexOf('player.vimeo.com/video')>0)
          idVimeo = videoUri.split("/").pop()
          VimeoToken.one().get().then((settings) ->
              Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
              video_uri = "videos/"+idVimeo
              Vimeo.one(video_uri).get().then((video_infos) ->
                if(video_infos.data.status == "available")
                  $scope._isAvailableVideo = true
                else
                  $scope._isAvailableVideo = false
              , (error) ->
                $scope._isAvailableVideo = false
              )
          , (error) ->
            $scope._isAvailableVideo = false
          )
      else
        $scope._isAvailableVideo = true

    $scope.deleteVimeoVideo = (idVimeo, model, field) ->
      # get Vimeo token api
      VimeoToken.one().get().then((settings) ->
          Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
          video_uri = "videos/"+idVimeo
          Vimeo.one(video_uri).remove().then((video_infos) ->
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
          # localStorage.setItem('vimeo_upload_token',settings.token)
          Vimeo.setDefaultHeaders({Authorization: "Bearer "+ settings.token})
          # connect to vimeo api
          Vimeo.one("me").get().then((account_infos) ->
              # console.log(account_infos)
              console.log((account_infos.data.upload_quota.space.free / 1073741824).toFixed(3) + " GB")
              upload_settings =
                type: "streaming"
              # get an upload ticket
              account_infos.data.customPOST(upload_settings,"videos").then((ticket) ->
                    # http method because Vimeo crash when multipart upload
                    #  send no Authorization
                    upload_config =
                      url: ticket.data.upload_link_secure
                      headers:
                        'Content-Type': data.type
                        Authorization : undefined
                      data: data
                      method: 'PUT'
                      transformRequest: (data, headers) ->
                        console.log(headers()['Authorization'])
                        delete headers()['Authorization']
                        return data;

                    Upload.http(upload_config)
                    .then((resp) ->
                        # Complete the upload : complete_uri remove
                        Vimeo.one(ticket.data.complete_uri).remove().then((remove) ->
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
                        console.log(error.headers('Authorization'))
                      , (evt) ->
                        $rootScope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total)

                    )
                  )
            )

        , ->
          # error
          console.log("vimeoUploadError")
      )

    $scope.uploadFile = (data, model, field) ->
      $rootScope.upload(data, model, field)



)

.controller('MessageController', (
        $rootScope, $scope
      ) ->

    $rootScope.loadInfos($rootScope)

    $scope.INTERVIEW_TYPES = ["Skype"]

    $rootScope.step.title = "Entretien"

    $scope.$watch('navigation_inter_page', (value) ->
        if(value == 0)
            $rootScope.current_display_screen = $rootScope.screen.message
            $rootScope.step.current = "14"
            $rootScope.step.title = "Entretien"
        if(value == 1)
            $rootScope.current_display_screen = $rootScope.screen.docs2
            $rootScope.step.current = "15"
            $rootScope.step.title = "Message"
        if(value == 2)
            $rootScope.current_display_screen = $rootScope.screen.docs3
            $rootScope.step.current = "16"
    )
)
.controller('FinalizationController', (
        $rootScope, $scope
      ) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.title = "Récapitulatif"

    $scope.$watch('navigation_inter_page', (value) ->
        if(value == 0)
            $rootScope.current_display_screen = $rootScope.screen.final
            $rootScope.step.current = "17"
            $rootScope.step.title = "Récapitulatif"
        if(value == 1)
            $rootScope.current_display_screen = $rootScope.screen.final2
            $rootScope.step.current = "18"
            $rootScope.step.title = "Validation"

    )
)
.controller('CompletedController', ($rootScope, $scope) ->
    $rootScope.loadInfos($rootScope)
    $rootScope.current_display_screen = $rootScope.screen.final3
    $rootScope.step.current = "19"
    $rootScope.step.title = "Complet"
  )
