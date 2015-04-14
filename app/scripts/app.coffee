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
                url: '/artist/:id',
                templateUrl: 'views/student.html'
                controller: 'ArtistController'
        )

        $stateProvider.state('artwork',
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
