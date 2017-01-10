###
Copyright (c) 2015 "Fuzzy Frequency, Le Fresnoy"

This file is part of Kartel.

Kartel is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
###

angular.module('memoire',
              [
                  'memoire.controllers', 'memoire.directives', 'ui.router',
                  'restangular', 'angular-jwt',
                  'ngAnimate', 'chieffancypants.loadingBar', 'ui.bootstrap',
                  'ngSanitize', 'markdown',
                  'iso-3166-country-codes', 'ngFileUpload', 'ngPlacesAutocomplete',
              ])

# CORS
.config(['$httpProvider', ($httpProvider) ->
        $httpProvider.defaults.useXDomain = true

        delete $httpProvider.defaults.headers.common['X-Requested-With']
])

# Tastypie
.config((RestangularProvider) ->
        RestangularProvider.setBaseUrl(config.rest_uri)
        # RestangularProvider.setRequestSuffix('?format=json');
        # RestangularProvider.setDefaultHeaders({"Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787"});
        # Tastypie patch
        RestangularProvider.setResponseExtractor((response, operation, what, url) ->
                newResponse = null;

                if operation is "getList"
                        #V2
                        newResponse = response
                        # V1
                        # newResponse = response.objects
                        # newResponse.metadata = response.meta
                else
                        newResponse = response

                return newResponse
        )
)

# token
 .config(($httpProvider, jwtOptionsProvider, RestangularProvider) ->
    # Please note we're annotating the function so that the $injector works when the file is minified
    jwtOptionsProvider.config({
      tokenGetter: ['options', (options) ->
        # myService.doSomething();
        return localStorage.getItem('id_token');
      ],
      # unauthenticatedRedirectPath: '/login',
      unauthenticatedRedirector: ['$state', ($state) ->
        console.log("unauthenticatedRedirector")
        # $state.go('candidature.login');

      ],
      whiteListedDomains: ['api.lefresnoy.net', 'localhost']

    })

    $httpProvider.interceptors.push('jwtInterceptor');

    if localStorage.getItem('id_token')
      RestangularProvider.setDefaultHeaders({Authorization: "JWT "+ localStorage.getItem('id_token')})
)
.run((authManager) ->

    authManager.checkAuthOnRefresh()
    authManager.redirectWhenUnauthenticated()

)

.run(['$rootScope' ,'$state', ($rootScope, $state) ->

  $rootScope.$on('tokenHasExpired', () ->
    console.log('Your session has expired!')
    console.log($state)
    setTimeout(() ->
      $state.go('candidature.account.login')
    ,200)

  )

])


.filter("isFresnoyUrl", ->
  return (input, str = "/media/") ->
    if typeof input isnt 'string'
      return false
    return input.indexOf(str) > -1

)

.filter('time', ->
    return (value, unit, format, isPadded) ->
      time = value.split(":")
      hh = time[0]
      mm = time[1]
      ss = time[2]

      if(hh!="0")
        return format.replace(/hh/, hh).replace(/mm/, mm).replace(/ss/, ss);
      if(hh=="0" && mm!="0")
        # regex  hh[^mm] mm cible l'heure (hh) jusqu'au prochain 'mm' sans le prendre en compte : [^mm]
        return format.replace(/\hh[^mm]+\h/, '').replace(/mm/, mm).replace(/ss/, ss);
      if(hh=="0" && mm=="0" && ss!="0")
        return format.replace(/ss/, ss);
)



# URI config
.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider,
                                                                      $stateProvider,
                                                                      $urlRouterProvider) ->

        $locationProvider.html5Mode(config.useHtml5Mode)
        $urlRouterProvider.otherwise("/school")

        # SCHOOL
        $stateProvider.state('school',
            url: '/school',
            views:
              'main_view':
                templateUrl: 'kartel.html'
              'main_view.main_content_view':
                  templateUrl: 'views/school.html'
                  controller: 'SchoolController'
        )

        $stateProvider.state('school.promotion',
              url: '/promotion/:id'
              views:
                'content_school_view':
                    templateUrl: 'views/promotion.html'
                    controller: 'PromotionController'
        )

        $stateProvider.state('school.student',
              url: '/student/:id'
              views:
                'content_school_view':
                    templateUrl: 'views/student.html'
                    controller: 'StudentController'

        )

        # ARTIST
        $stateProvider.state('artist',
                url: '/artist?letter'
                views:
                  'main_view':
                      templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                    templateUrl: 'views/artists.html'
                    controller: 'ArtistListingController'
        )

        $stateProvider.state('artist.detail',
                url: '/:id',
                views:
                  'school_content_view':
                    templateUrl: 'views/student.html'
                    controller: 'ArtistController'
        )

        # ARTWORK

        $stateProvider.state('genre',
                url: '/artwork/?genre'
                views:
                  'main_view':
                    templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                      templateUrl: 'views/artworks.html'
                      controller: 'ArtworkGenreListingController'
        )

        $stateProvider.state('artwork',
                url: '/artwork?letter&offset'
                views:
                  'main_view':
                      templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                      templateUrl: 'views/artworks.html'
                      controller: 'ArtworkListingController'
        )

        $stateProvider.state('artwork-detail',
                url: '/artwork/:id'
                views:
                  'main_view':
                    templateUrl: 'kartel.html'
                  'main_view.main_content_view':
                      templateUrl: 'views/artwork.html'
                      controller: 'ArtworkController'
        )

        # ACCOUNT
        $stateProvider.state('account',
                url: '/account'
                views:
                  'main_view':
                    templateUrl: 'views/account/index.html'
                    controller: 'ParentAccountController'
        )


        # - Candidature

        # - Candidature Root
        $stateProvider.state('candidature',
                url: '/candidature'
                views:
                  # 'navigation_view':
                  #    templateUrl: 'views/partials/navigation-application.html'
                  'main_view':
                    templateUrl: 'views/candidature/index.html'
                    controller: 'ParentCandidatureController'

                  'main_view.application_content_view':
                      templateUrl: 'views/candidature/home.html'

                  'main_view.application_step_view':
                      templateUrl: 'views/candidature/partials/step-infos.html'

                  'main_view.application_account_view':
                      templateUrl: 'views/candidature/account/account-status.html'
                      controller: 'AccountBarController'
        )
        # ACCOUNT
        $stateProvider.state('candidature.account',
                  url: '/account'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/account/index.html'
                    'application_step_view':
                        templateUrl: 'views/candidature/partials/step-infos.html'
        )

        $stateProvider.state('candidature.account.login',
                url: '/login'
                views:
                  'account_content_view':
                      templateUrl: 'views/candidature/account/login.html'
                      controller: 'LoginController'
        )

        $stateProvider.state('candidature.account.reset-password',
                  url: '/reset-password/:token/:route'
                  views:
                    'account_content_view':
                        templateUrl: 'views/candidature/account/reset_password.html'
                        controller: 'AccountChangePasswordController'
        )

        $stateProvider.state('candidature.account.password-forgot',
                  url: '/passworg-forgot'
                  views:
                    'account_content_view':
                        templateUrl: 'views/candidature/account/password_forgot.html'
                        controller: 'AccountPasswordAskController'
        )


        $stateProvider.state('candidature.account.change-password-with-token',
                  url: '/change-password/:token/:route'
                  views:
                    'account_content_view':
                        templateUrl: 'views/candidature/account/change_password.html'
                        controller: 'AccountChangePasswordController'
        )


        # Create User
        $stateProvider.state('candidature.account.create-user',
                  url: '/identification'
                  views:
                    'account_content_view':
                      templateUrl: 'views/candidature/account/identification.html'
                      controller: 'IdentificationController'
        )

        # Candidature 01 - Confirm User
        $stateProvider.state('candidature.account.confirm-user',
                  url: '/identification-confirmation'
                  views:
                    'account_content_view':
                        templateUrl: 'views/candidature/account/identification-confirmation.html'
                        controller: 'AccountConfirmationController'
        )


        # Candidature 01 - Resume or new App
        $stateProvider.state('candidature.resume',
                  url: '/resume'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/resume.html'
                        controller: 'ResumeAppController'
        )


        # Candidature 03 - etat-civil
        $stateProvider.state('candidature.etat-civil-1',
                  url: '/etat-civil-1'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/etat_civil.html'
                        controller: 'CivilStatusController'
                  requiresLogin: true

        )

        # Candidature 04 - Adresse
        $stateProvider.state('candidature.etat-civil-adress',
                    url: '/etat-civil-adress'
                    views:
                      'application_content_view':
                          templateUrl: 'views/candidature/etat_civil_adress.html'
                          controller: 'CivilStatusAdressController'
                    requiresLogin: true

        )

        # Candidature 05 - Languages
        $stateProvider.state('candidature.etat-civil-language',
                    url: '/etat-civil-language'
                    views:
                      'application_content_view':
                          templateUrl: 'views/candidature/etat_civil_language.html'
                          controller: 'CivilStatusLanguageController'
                    requiresLogin: true

        )

        # Candidature 06 - etat-civil_photo
        $stateProvider.state('candidature.etat-civil-photo',
                  url: '/photo'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/etat_civil_photo.html'
                        controller: 'ProfilePhotoController'
                  requiresLogin: true

        )

        # Candidature 07 - cursus
        $stateProvider.state('candidature.cursus',
                  url: '/cursus'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/cursus.html'
                        controller: 'CursusController'
                  requiresLogin: true

        )

        # Candidature 08 - Media
        $stateProvider.state('candidature.media',
                    url: '/media'
                    views:
                      'application_content_view':
                          templateUrl: 'views/candidature/media.html'
                          controller: 'MediaController'
                    requiresLogin: true

        )

        # Candidature 09 - Message
        $stateProvider.state('candidature.message',
                    url: '/message'
                    views:
                      'application_content_view':
                          templateUrl: 'views/candidature/message.html'
                          controller: 'MessageController'
                    requiresLogin: true

        )
        # Candidature 10 - Confirmation
        $stateProvider.state('candidature.confirmation',
                    url: '/confirmation'
                    views:
                      'application_content_view':
                          templateUrl: 'views/candidature/confirmation.html'
                          controller: 'ConfirmationController'
                    requiresLogin: true

        )


        # Candidature FIN - completed
        $stateProvider.state('candidature.completed',
                  url: '/completed'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/finish.html'
                       # controller: 'CursusController'
                  requiresLogin: true

        )


        # Candidature
        $stateProvider.state('candidature.step',
                  url: '/:lang/:step'
                  views:
                    # @ root view
                    'main_content_view@':
                        templateUrl: 'views/candidature/form.html'
                        controller: 'CandidatureFormController'

                    'main_content_view.application_breadcrumb_view':
                        templateUrl: 'views/candidature/breadcrumb.html'
                        controller: 'CandidatureBreadCrumbController'
        )


])

.run(['$rootScope', '$state', '$stateParams', ($rootScope, $state, $stateParams) ->
        $rootScope.homeStateName = 'apps' # Should be moved to loginServiceProvider

        $rootScope.config = config
        $rootScope.$state = $state
        $rootScope.$stateParams = $stateParams
        # $rootScope.loginService = loginService
])

.run(['AmeRestangular', (AmeRestangular) ->
  AmeRestangular.setErrorInterceptor((response) ->
    if (response.status == 401)
        console.log("Login required... ")
    else if (response.status == 404)
        console.log("Resource not available...")
    else
        console.log("Ame service not available : " + response.status )
    return response # stop the promise chain
  )
])

# Ugly Fix for autofill on forms
.directive('formAutofillFix', ->
        (scope, elem, attrs) ->
        # Fixes Chrome bug: https://groups.google.com/forum/#!topic/angular/6NlucSskQjY
        elem.prop 'method', 'POST'

        # Fix autofill issues where Angular doesn't know about autofilled inputs
        if attrs.ngSubmit
                setTimeout ->
                        elem.unbind('submit').submit (e) ->
                                e.preventDefault()
                                elem.find('input, textarea, select').trigger('input').trigger('change').trigger('keydown', ->
                                        scope.$apply(attrs.ngSubmit)
                                , 0)
)
