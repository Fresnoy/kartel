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

angular.module('memoire', ['memoire.controllers', 'memoire.directives', 'ui.router', 'ngAnimate', 'restangular', 'chieffancypants.loadingBar', 'ui.bootstrap', 'ngSanitize', 'markdown'])

# CORS
.config(['$httpProvider', ($httpProvider) ->
        $httpProvider.defaults.useXDomain = true

        delete $httpProvider.defaults.headers.common['X-Requested-With']
])

# Tastypie
.config((RestangularProvider) ->
        RestangularProvider.setBaseUrl(config.rest_uri)
        RestangularProvider.setRequestSuffix('?format=json');
        # RestangularProvider.setDefaultHeaders({"Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787"});
        # Tastypie patch
        RestangularProvider.setResponseExtractor((response, operation, what, url) ->
                newResponse = null;

                if operation is "getList"
                        newResponse = response.objects
                        newResponse.metadata = response.meta
                else
                        newResponse = response

                return newResponse
        )
)

# AME Service
.factory('AmeRestangular', (Restangular) ->

      Restangular.setDefaultRequestParams({key: config.ame_key})
      #

      return Restangular.withConfig((RestangularConfigurer) ->
         #console.log(RestangularConfigurer)
            RestangularConfigurer.setBaseUrl(config.ame_rest_uri);

            #RestangularConfigurer.defaultRequestParams.common.apikey = config.ame_key;
            #Restangular.setDefaultRequestParams({key: config.ame_key});
      )
)

.filter("isFresnoyUrl", ->
  return (input, str = "/media/") ->
    if typeof input isnt 'string'
      return false
    return input.indexOf(str) > -1


)


# URI config
.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider, $stateProvider, $urlRouterProvider) ->
        $locationProvider.html5Mode(config.useHtml5Mode)
        $urlRouterProvider.otherwise("/")

        $stateProvider.state('home',
                url: '/',
                templateUrl: 'views/school.html'
                controller: 'SchoolController'
        )

        $stateProvider.state('school',
                url: '/school',
                templateUrl: 'views/school.html'
                controller: 'SchoolController'
        )
        $stateProvider.state('school.promotion',
                url: '/promotion/:id',
                templateUrl: 'views/promotion.html'
                controller: 'PromotionController'
        )

        $stateProvider.state('school.student',
                url: '/student/:id',
                templateUrl: 'views/student.html'
                controller: 'StudentController'
        )

        $stateProvider.state('artist',
                url: '/artist?letter',
                templateUrl: 'views/artists.html'
                controller: 'ArtistListingController'
        )

        $stateProvider.state('artist.detail',
                url: '/:id',
                templateUrl: 'views/student.html'
                controller: 'ArtistController'
        )

        $stateProvider.state('artwork',
                url: '/artwork?letter',
                templateUrl: 'views/artworks.html'
                controller: 'ArtworkListingController'
        )

        $stateProvider.state('artwork-detail',
                url: '/artwork/:id',
                templateUrl: 'views/artwork.html'
                controller: 'ArtworkController'
        )



])

.run(['$rootScope', '$state', '$stateParams', ($rootScope, $state, $stateParams) ->
        $rootScope.homeStateName = 'apps' # Should be moved to loginServiceProvider

        $rootScope.config = config
        $rootScope.$state = $state
        $rootScope.$stateParams = $stateParams
        # $rootScope.loginService = loginService
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
