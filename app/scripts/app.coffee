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
      unauthenticatedRedirectPath: '/login',
      unauthenticatedRedirector: ['$state', ($state) ->
        #$state.go('app.login');
        console.log("authredirector")

      ],
      whiteListedDomains: ['api.lefresnoy.net', 'localhost']

    })

    $httpProvider.interceptors.push('jwtInterceptor');
    RestangularProvider.setDefaultHeaders({Authorization: "JWT "+localStorage.getItem('id_token')})
)
.run((authManager) ->

    # authManager.checkAuthOnRefresh()
    # authManager.redirectWhenUnauthenticated()

)

.run(['$rootScope' ,'$state', ($rootScope, $state) ->

  #console.log($rootScope)

  $rootScope.$on('tokenHasExpired', () ->
    console.log('Your session has expired!')
    # $state.go('apps.candidature')
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
.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider, $stateProvider, $urlRouterProvider) ->
        $locationProvider.html5Mode(config.useHtml5Mode)
        $urlRouterProvider.otherwise("/")


        $stateProvider.state('home',
            url: '/'
            views:
              'navigation_view':
                  templateUrl: 'views/partials/navigation.html'
              'main_content_view':
                  templateUrl: 'views/school.html'
                  controller: 'SchoolController'

        )

        # SCHOOL
        $stateProvider.state('school',
            url: '/school',
            views:
              'navigation_view':
                  templateUrl: 'views/partials/navigation.html'
              'main_content_view':
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
                views: {
                  'navigation_view': {
                      templateUrl: 'views/partials/navigation.html'
                  }
                  'main_content_view': {
                    templateUrl: 'views/artists.html'
                    controller: 'ArtistListingController'
                  }
                }

        )

        $stateProvider.state('artist.detail',
                url: '/:id',
                views: {
                  'navigation_view': {
                      templateUrl: 'views/partials/navigation.html'
                  }
                  'school_content_view': {
                    templateUrl: 'views/student.html'
                    controller: 'ArtistController'
                  }
                }

        )

        # ARTWORK

        $stateProvider.state('genre',
                url: '/artwork/?genre',
                views: {
                  'navigation_view': {
                      templateUrl: 'views/partials/navigation.html'
                  }
                  'main_content_view': {
                      templateUrl: 'views/artworks.html'
                      controller: 'ArtworkGenreListingController'
                  }
                }
        )

        $stateProvider.state('artwork',
                url: '/artwork?letter&offset',
                views: {
                  'navigation_view': {
                      templateUrl: 'views/partials/navigation.html'
                  }
                  'main_content_view': {
                      templateUrl: 'views/artworks.html'
                      controller: 'ArtworkListingController'
                  }
                }

        )
        $stateProvider.state('artwork-detail', {
                url: '/artwork/:id'
                views: {
                  'navigation_view': {
                      templateUrl: 'views/partials/navigation.html'
                  }
                  'main_content_view': {
                      templateUrl: 'views/artwork.html'
                      controller: 'ArtworkController'
                  }
                }
            }
        )

        # - Candidature 00
        $stateProvider.state('candidature',
                url: '/candidature'
                views:
                  # 'navigation_view':
                  #    templateUrl: 'views/partials/navigation-application.html'
                  'main_content_view':
                      templateUrl: 'views/candidature/home.html'
                      controller: 'InitCandidatureController'
                  'main_content_view.application_breadcrumb_view':
                      templateUrl: 'views/candidature/breadcrumb.html'
                      controller: 'CandidatureBreadCrumbController'
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
