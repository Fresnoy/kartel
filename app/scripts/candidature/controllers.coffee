# -*- tab-width: 2 -*-
"use strict"

angular.module('candidature.controllers', ['memoire.services', 'candidature.services'])


#
.controller('AccountCreationController',($rootScope, $http, $scope, $state, Registration, RestangularV2, Users) ->
      # inscription
      $rootScope.step.current = "04"
      $rootScope.current_display_screen = candidature_config.screen.account_create_user

      $rootScope.logout()

      # init user form
      if(!$scope.user)
        $scope.user =
            last_name: ''
            first_name: ''
            email: ''

      # autogenerate username
      $scope.setUserName = (form, user) ->
        if (!user.first_name || !user.last_name)
          return
        user.username = slug(user.first_name).toLowerCase().substr(0,1) + slug(user.last_name).toLowerCase()
        form.uUserName.$setTouched()

      # create user
      $scope.create = (form, params) ->
        Registration.post(params).then((response) ->
          $state.go('candidature.account.user-created', {infos:params})
        , (response) ->
          console.log response.data
          form.error = response.data
        )


)
.controller('AccountConfirmCreationController',($rootScope, $http, $scope, $state, Registration, RestangularV2, Users, $stateParams) ->
    $rootScope.step.current = "05"
    $rootScope.current_display_screen = candidature_config.screen.account_confirm_creation
    $scope.edit_email = false
    $scope.send_email = 2

    if($stateParams.infos)
      $scope.user = $stateParams.infos

    $scope.update_infos = (form, params) ->
      delete $http.defaults.headers.common.Authorization
      form.$setSubmitted()
      RestangularV2.all('people/user/resend_activation_email').post(params).then((response) ->
        $scope.send_email--
      , (response) ->
        form.$error = response.data

      )
)


.controller('AccountCreatePasswordController', (
        $rootScope, $scope, $stateParams, $http,
        $state, jwtHelper, RestAuth, Restangular
) ->

  $rootScope.step.current = "06"
  $rootScope.current_display_screen = candidature_config.screen.account_create_password
  $scope.user_id = false

  if($stateParams.token)

    tokenDecode = []
    try tokenDecode = jwtHelper.decodeToken($stateParams.token)
    catch e then tokenDecode.user_id = false

    route = $stateParams.route
    $scope.user_id = tokenDecode.user_id
    $scope.username = tokenDecode.username

    $scope.submit = () ->
      # delete old headers
      delete $http.defaults.headers.common.Authorization

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

.controller('AccountPasswordResetController', ($rootScope, $scope, RestAuth, Users) ->

  $rootScope.step.current = "06"

  $scope.emailSended = false;

  $scope.checkMail = (form, email) ->
    Users.getList({search: email}).then((data) ->
        form.$setValidity('knowemail', data.length == 1)
        form.$setTouched()
    )


  $scope.submit = () ->
      RestAuth.one().customPOST({email: $scope.email}, "password/reset/").then((response) ->
        $scope.emailSended = true;
      , (response) ->
        $scope.form.error = "Erreur d'envoie de l'email"
  )
)

.controller('AccountLoginController', (
  $rootScope, $scope, RestangularV2, $state, $http, Login,
  Logout, Users, authManager, jwtHelper
                                ) ->

    $rootScope.step.current = "07"
    $rootScope.current_display_screen = candidature_config.screen.account_login

    $scope.vm =
      username:""
      user_or_email:""
      password:""

    if($scope.isAuthenticated)
      console.log("logged : resume candidature")
      $state.go("candidature.options")

    $scope.searchUserName = (form, str) ->
      $scope.vm.username = "";
      form.uNameOrEmail.$setValidity('unknown', false)
      Users.getList({search: str}).then((data) ->
          if(data.length == 1)
            $scope.vm.username = data[0].username
            form.uNameOrEmail.$setValidity('unknown', true)
          if(data.length > 1)
            form.uNameOrEmail.$setValidity('toomany', true)
      )

    $scope.login = (form, params) ->
      delete $http.defaults.headers.common.Authorization
      Login.post(params, [headers={}])
      .then((auth) ->
            localStorage.setItem('token', auth.token)
            # set header
            $http.defaults.headers.common.Authorization = "JWT "+ localStorage.getItem('token')
            authManager.authenticate() 
            $state.go("candidature.options")
          , () ->
            console.log("error")
            params.error = "Error login"
            $scope.logout("candidature.account.login")
     )
)


.controller('CandidatureBreadcrumbController', ($rootScope, $scope, $state) ->

    $scope.getProgression = (type) ->
      if(!$scope.isAuthenticated || !$rootScope.candidature)
        return false

      if(type == "administrative-informations")
        ar = [$rootScope.user.last_name, $rootScope.user.first_name,
          $rootScope.user.profile.gender, $rootScope.user.profile.birthdate,
          $rootScope.user.profile.birthplace_country,
          $rootScope.candidature.identity_card,$rootScope.user.profile.nationality,
          $rootScope.user.profile.photo, $rootScope.user.profile.homeland_phone,
          $rootScope.user.profile.mother_tongue, $rootScope.user.profile.homeland_address,
          $rootScope.user.profile.homeland_zipcode,
          $rootScope.user.profile.homeland_town, $rootScope.user.profile.homeland_country]
        total = ar.length
        progress = 0
        for item in ar
          if(item)
            progress++
        return $scope.progress_admin = progress/total*100

      if(type == "curiculum")
        total = 2
        progress = 0
        if(($rootScope.candidature.master_degree=="Y" && $rootScope.cursus_justifications.media.length) ||
           $rootScope.candidature.master_degree=="P" ||
          (!$rootScope.candidature.master_degree=='N' && $rootScope.candidature.experience_justification)
        )
          progress++
        if($rootScope.candidature.curriculum_vitae)
          progress++
        return $scope.progress_curiculum = progress/total*100

      if(type == "portfolio")
         total = 3
         progress = 0
         if($rootScope.user.profile.cursus)
            progress++
         if($rootScope.candidature.presentation_video)
            progress++
         if($rootScope.candidature.presentation_video_details)
           progress++

         return $scope.progress_portfolio = progress/total*100

      if(type == "intentions")
          ar = [$rootScope.candidature.justification_letter,
            $rootScope.candidature.considered_project_1,
            $rootScope.candidature.considered_project_2,
            $rootScope.candidature.artistic_referencies_project_1,
            $rootScope.candidature.artistic_referencies_project_2]
          total = ar.length
          progress = 0
          for item, i in ar
            if(item)
              progress++
          if($rootScope.candidature.binomial_application)
              total++
              if($rootScope.candidature.binomial_application_with)
                  progress++

          return $scope.progress_intentions = progress/total*100

    $scope.progress_admin = 0
    $scope.progress_curiculum = 0
    $scope.progress_portfolio = 0
    $scope.progress_intentions = 0



)
  # Media
.controller('ParentCandidatureController', ($rootScope, $scope, $state, jwtHelper, $q,
            Restangular, RestangularV2, Vimeo, Logout, $http, cfpLoadingBar, authManager, ISO3166,
            Users, Candidatures, ArtistsV2, Galleries, Media, Upload, ) ->

  $rootScope.main_title= "Le Fresnoy - Studio national - Selection"

  # Media
  if(!$rootScope.current_display_screen)
    $rootScope.current_display_screen = candidature_config.screen.home

  # Get candidature Setup
  $rootScope.campaign = {}
  $rootScope.timer_countdown = 0

  $scope.countdownFinish = () ->
    # wait 2 seconds before get new setup 
    setTimeout( ->
          $scope.getCandidatureSetup()
        , 2000)

  $scope.getCandidatureSetup = () ->

    console.log("getCandidature setup")
    RestangularV2.all('school/student-application-setup').getList({'is_current_setup': "true"})
    .then((setup_response) ->
        # console.log("Candidature setup")
        $rootScope.campaign = setup_response[0]
        
        current_date = new Date()
        # set by server api
        # scope.campaign.candidature_open = new Date(scope.campaign.candidature_date_start) < current_date && current_date < new Date(scope.campaign.candidature_date_end)
        $rootScope.campaign.candidature_close = new Date() > new Date($rootScope.campaign.candidature_date_end)

        # get promo before redirect text possible redirect : The application phase for year/year is now closed.
        id_promo = setup_response[0].promotion.match(/\d+$/)[0]
        Restangular.one("school/promotion/"+id_promo).get().then((promo_response) ->
          $rootScope.campaign.promotion = promo_response
        )

        # candidature are not open
        if ($rootScope.redirectCandidatureIfClosedOrCompleted())
          # break 
          return

        

        # setup countdown
        $rootScope.timer_countdown = Math.round((new Date($rootScope.campaign.candidature_date_end).getTime() - new Date().getTime())/1000)
        # have to adjust countdown because 1 second = 1.001 second depending on the browser (WTF?!)
        setInterval( ->
          # console.log "countdown adjust"
          $rootScope.timer_countdown = Math.round((new Date($rootScope.campaign.candidature_date_end).getTime() - new Date().getTime())/1000) 
          $rootScope.$broadcast('timer-set-countdown', $rootScope.timer_countdown);
        , 60*1000)

    ,() ->
          #error
          console.log("server api problem")
          $state.go('candidature.error')
    )
  $scope.getCandidatureSetup()


  # root function redirection
  $rootScope.redirectCandidatureIfClosedOrCompleted = () ->
    
    # console.log('redirect candidature')
    
    if ($rootScope.candidature && $rootScope.candidature.application_completed)
         $state.go("candidature.confirmation")
         return true
    

    if ($rootScope.campaign && !$rootScope.campaign.candidature_open)
        current_date = new Date()
        candidature_start = new Date($rootScope.campaign.candidature_date_start) 
        candidature_end = new Date($rootScope.campaign.candidature_date_end) 
        # pending?
        if (current_date < candidature_start)
          # console.log("pending")
          $state.go('candidature.pending')
          # redirected
          return true
          
        # expired ?
        if (current_date > candidature_end)
          # console.log("expired")
          $state.go('candidature.expired')
          # redirected
          return true
           
    # no redirection
    return false
  

  # init step in parent controller
  $rootScope.step = []
  $rootScope.step.total = 25
  # $rootScope.step.title = "Procédure d'inscription"
  $rootScope.candidature_config = candidature_config

  # navigation
  $rootScope.navigation_inter_page = 0
  $rootScope.display_help = false
  $rootScope.help_exist = false
  $rootScope.show_help = (bool) ->
    $rootScope.help_exist=true
    if(bool!=undefined)
      return $rootScope.display_help = bool
    $rootScope.display_help = !$rootScope.display_help

  # Dates
  $rootScope.current_year = new Date().getFullYear()
  $rootScope.age_min = 18

  # phone
  $rootScope.phone_pattern = /^\+?[0-9-]{2,5}[-. ]?\d{5,12}$/

  # ITW types
  # $scope.INTERVIEW_TYPES = [""]

  # write data var
  $rootScope.writingData = false

  # lang
  if localStorage.getItem("language")
    $rootScope.language = localStorage.getItem("language")
  else
    localStorage.language = "fr"
    $rootScope.language = localStorage.getItem("language")

  $scope.setLang = (lang) ->
    localStorage.setItem("language", lang)
    $rootScope.language = localStorage.language

  # countries
  $rootScope.getCountrie = (code) ->
    return _.invert(ISO3166.countryToCode)[code]


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

  $scope.saveUserModel = (model) ->
    model_copy =  RestangularV2.copy(model)
    if model_copy.profile.photo
      delete model_copy.profile.photo
    model_copy.save()


  #load user infos
  $rootScope.loadInfos = (scope) ->

    # console.log("loadinfos")
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

    # redirect if not auth
    if(!scope.isAuthenticated)
        $state.go("candidature.account.login")
        return

    user_id = jwtHelper.decodeToken(localStorage.getItem('token')).user_id
    Users.one(user_id).get().then((user) ->
      scope.user = user
      # search for a candidature for this user
      search_current_application = {'search':user.username, 'campaign__is_current_setup':"true"}
      Candidatures.getList(search_current_application).then((candidatures) ->
        if(!candidatures.length)

          # redirect if candidature is expired (can't create candidature)
          if($rootScope.redirectCandidatureIfClosedOrCompleted()) 
              return
          
          # CREATE A CANDIDATURE
          Candidatures.post().then((candidature) ->
            # reload infos
            $rootScope.loadInfos(scope)
          ,(userInfos_error) ->
            console.log("creation de candidature echouée")
            $state.go("candidature.error")
          )
          return
        else
          # candidature exist
          candidature = candidatures[0]
          scope.candidature = candidature
          # redirect candidature complete or 
          # redirect if candidature is expired
          if($rootScope.redirectCandidatureIfClosedOrCompleted()) 
              return
          # get galleries
          if(scope.candidature.cursus_justifications)
            getGalleryWithMedia(scope.candidature.cursus_justifications, scope.cursus_justifications)
          else
            # CREATE GALLERIES
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
                for website in artist.websites
                    website_id = website.match(/\d+$/)[0]
                    RestangularV2.one('common/website', website_id).get().then((response_website) ->
                        find_website = artist.websites.indexOf(response_website.url)
                        artist.websites[find_website] = response_website
                    )
            )


      ,(candidatureInfos_error) ->
        console.log("error Candidatures infos")
        $state.go("candidature.error")
      )
    , (userInfos_error) ->
      console.log("error user infos")
      $state.go("candidature.error")
    )
)


.controller('OptionsController', ($rootScope, Users, jwtHelper, $state) ->
      $rootScope.step.current = "08"

      if($rootScope.redirectCandidatureIfClosedOrCompleted()) 
          return
      
      # if this is his first connection -> option 
      # otherwise -> resume 
      user_id = jwtHelper.decodeToken(localStorage.getItem('token')).user_id
      Users.one(user_id).get().then((user) ->
        if(user.profile.is_artist)
          $state.go("candidature.summary")
        else
          $rootScope.loadInfos($rootScope)
      )
)


.controller('AdministrativeInformationsController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

  # input date gros bug avec safari !
  $scope.is_safari = /^((?!chrome|android).)*safari/i.test(navigator.userAgent)
  $scope.safari_birthdate_value = null

  $scope.safari_keyup = (event, scope) =>
    # move cursor to one more when auto insert '/'
    target = event.currentTarget
    char_num = target.selectionStart
    char_str = scope.safari_birthdate_value.split('')[char_num]

    if(char_str == "/")
        char_num++
        form1.uBirthDate.setSelectionRange(char_num, char_num)

  $scope.safari_birthdate_change = (value) =>
    if(value)
      transform = value
        # Remove all non-digits
        .replace(/\D+/g, '')
        # Stick to first 10, ignore later digits
        .slice(0, 8)
        # day 0 -> 31
        .replace(/^([^0-3])/, '')
        .replace(/^3([^01])(.*)/, '3$2')
        # month 1 -> 12
        .replace(/^(.{2})([^01]|1[^0-2])/, '$1')
        # Add a space after any 2-digit group followed by more digits
        .replace(/^(\d{2})/g, '$1/')
        .replace(/^(\d{2}).?(\d{2})/g, '$1/$2/')
        #
      # angular error emulate
      error = {}
      # safari know date like yyyy/MM/dd
      user_birthdate = new Date(transform.split('/').reverse().join('/'))

      date_min = new Date($rootScope.campaign.date_of_birth_max.split('-').join('/'))
      date_max = new Date($rootScope.current_year-$rootScope.age_min+1,0,0)

      if(user_birthdate < date_min)
        error.min = true

      if(user_birthdate > date_max)
        error.max = true

      # emulate error to display as input date
      $scope.form1.uBirthDate.$error = error
      $scope.form1.uBirthDate.$validate()

      return transform

  $rootScope.loadInfos($rootScope)
  $rootScope.step.current = "09"
  $rootScope.current_display_screen = candidature_config.screen.admin_infos

  $scope.birthdateMin = $filter('date')(new Date($rootScope.campaign.date_of_birth_max), 'yyyy-MM-dd')
  $scope.birthdateMax = $filter('date')(new Date($rootScope.current_year-$rootScope.age_min+1,0,0), 'yyyy-MM-dd')
  $scope.birthdate = { value: new Date($rootScope.current_year-$rootScope.age_max+1,0,0) }

  $scope.$watch("user.profile.birthdate", (newValue, oldValue) ->
    if(newValue)
      $scope.birthdate.value = new Date(newValue)
      $scope.safari_birthdate_value = newValue.split('-').reverse().join('/')
  )
  $scope.$watch("campaign", (newValue, oldValue) ->
    if(newValue)
      $scope.birthdateMin = $filter('date')(new Date($rootScope.campaign.date_of_birth_max), 'yyyy-MM-dd')
  )

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



  # justif photo
  $scope.photo_justification_file = null

  $scope.uploadFile = (data, model, field, type) ->
    $rootScope.upload(data, model, field)


  # specific upload Photo

)

.controller('ContactInformationsController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "10"
    $rootScope.current_display_screen = candidature_config.screen.admin_infos

    #country
    $scope.countries = ISO3166.countryToCode

    $scope.$watch("user.profile.homeland_phone", (newValue, oldValue) ->
      if(newValue)
        $scope.phone_number = newValue.split("-").pop()
        $scope.phone_country = newValue.split("-").shift().substr(1)

        if($scope.form2.uHomelandPhone.$valid)
          $scope.saveUserModel($scope.user)
    )


)

.controller('LanguagesInformationsController', ($rootScope, $scope, $state, $filter, ISO3166,
        Restangular, RestangularV2, Media, Upload) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "11"
    $rootScope.current_display_screen = candidature_config.screen.languages_infos

    $scope.languageSelectOption =
      fr:"Sélectionner une langue"
      en:"Select a language"

    $scope.LANGUAGES_NAME = languageMappingList
    $scope.LANGUAGES = _.sortBy(_.pairs(languageMappingList), (o) -> return o[1].englishName)
    $scope.other_language = []
    $scope.splitChar = ", "

    $scope.$watch("user.profile.other_language", (newValue, oldValue) ->
      if(newValue)
        $scope.other_language =   newValue.split($scope.splitChar)
    )



)
.controller('UploadUserPhotoController', ($rootScope, $scope, $state, Upload) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "12"
    $rootScope.current_display_screen = candidature_config.screen.photo_info

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
.controller('CvController', ($rootScope, $scope, Media, Galleries, Upload) ->

      $rootScope.loadInfos($rootScope)
      $rootScope.step.current = "14"
      $rootScope.current_display_screen = candidature_config.screen.cv


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

      $scope.removeItem = (media, index) ->
        item = media[index]
        item.remove().then((response) ->
            media.splice(index,1)
        )
)
.controller('ArtisticBgController', ($rootScope, $scope, WebsiteV2) ->

        $rootScope.loadInfos($rootScope)
        $rootScope.step.current = "15"

        $scope.addWebsite = (artist, model, field) ->
          # console.log(field)

          if(!/^https?:\/\//i.test(field))
            field = 'http://' + field;


          # console.log(field)
          # console.log(field.indexOf('://'))


          website_infos =
            link: field
            title_fr: "Site web de " + $rootScope.user.first_name + " " + $rootScope.user.last_name
            title_en: "Website " + $rootScope.user.first_name + " " + $rootScope.user.last_name
            language: localStorage.getItem("language").toUpperCase()

          WebsiteV2.one().customPOST(website_infos).then((response_website) ->
              model.push(response_website)
              infos = []
              infos.push(item.url) for item in model
              artist.patch({websites: infos})
              $scope.website = ""

          , (error) ->
                $scope.form.aWebsite.$invalid = true
                $scope.form.aWebsite.$error.url = true

          )
        $scope.removeItem = (model, index) ->
          item = model[index]
          item.remove().then((response) ->
              model.splice(index,1)
          )
)


.controller('PreviousAppController', ($rootScope, $scope, Media, Galleries, Upload) ->

        $rootScope.loadInfos($rootScope)
        $rootScope.step.current = "17"

        #cursus
        year = new Date().getFullYear()
        $scope.years = []
        $scope.years.push (year-i) for i in [1..35]

        $scope.last_applications_years = []
        $scope.splitChar = ", "

        $scope.$watch("candidature.last_applications_years", (newValue, oldValue) ->
          if(newValue)
            $scope.last_applications_years = newValue.split($scope.splitChar)
        )

)


.controller('FinalizationAppController', ($rootScope, $state, $scope, Media, Galleries, Upload) ->

        $rootScope.loadInfos($rootScope)
        $rootScope.step.current = "24"

        $scope.status_class = ""

        # make sure server set the app complete to true (if ok it send email to candidat and admin)
        $scope.final_submission = (candidature) ->
          # disabled click
          $scope.status_class = "disabled"
          # send the value
          candidature.patch({application_completed: true}).then((response) ->
            # send is ok
            # last value checking
            if (response.application_completed)
              $state.go('candidature.confirmation')

          , (error) ->
            console.log("server api or connection problem")
            $state.go('candidature.error')
          )


)

# media
.controller('MediaVideoController', (
        $rootScope, $scope, $q, $state, $filter, $sce, $http,
        Users, ArtistsV2, Restangular, RestangularV2, Candidatures, Media, Galleries,
        ISO3166, Upload, VimeoToken, Vimeo
      ) ->

    $rootScope.loadInfos($rootScope)
    $rootScope.step.current = "16"

    $scope.trustSrc = (src) ->
      return $sce.trustAsResourceUrl(src);

    $scope.honor = false

    $scope.$watch("candidature.presentation_video", (newValue, oldValue) ->
      if(newValue)
        $scope.isAvailableVideo(newValue)

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
                      skipAuthorization: true,
                      # transformRequest: (data, headers) ->
                      #   delete headers()['Authorization']
                      #   return data;

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
                            # put video in album 4943258 (candidature 2018)
                            album_id = 4943258
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
