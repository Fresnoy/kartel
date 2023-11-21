# -*- tab-width: 2 -*-
"use strict"
angular.module('candidature.application', ['candidature.controllers',
            'ui.router', 'timer'
])

.run(['$rootScope', '$state', 'jwtHelper', ($rootScope, $state, jwtHelper) ->
  # TOKEN IS EXPIRED
  $rootScope.$on('tokenHasExpired', () ->
    # get date to debug
    try date = jwtHelper.getTokenExpirationDate(localStorage.getItem('token'));
    catch e then date = false
    console.log('Your session has expired on ', date)
    # test if system know how to logout
    if(typeof $rootScope.logout is 'function') # 'is' equal to '===' in CoffeeScript
      # do logout
      $rootScope.logout()
    # try to know where we are, many ways !
    location = if $state.$urlRouter then $state.$urlRouter.location else if $state.router.urlRouter then $state.router.urlRouter.location else undefined
    # if candidature context go to login
    if(location.indexOf("candidature/")!=-1)
      # timed redirection ... for debug ? 
      setTimeout(() ->
        $state.go('candidature.account.login')
      , 200)
  )
])
.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider,
                                                                      $stateProvider,
                                                                      $urlRouterProvider) ->
      # - CANDIDATURE Root
      $stateProvider.state('candidature',
              url: '/candidature'
              views:
                'main_view':
                  templateUrl: 'views/candidature/index.html',
                  controller: 'ParentCandidatureController'

                'main_view.application_content_view':
                    templateUrl: 'views/candidature/pages/01-landing-page.html',
                    controller: ($rootScope) ->
                      $rootScope.step.current = "01"
                      # this is first page !
                      # load infos if candidat has token on the first page
                      if($rootScope.isAuthenticated)
                        $rootScope.loadInfos($rootScope)
                      # try to redirect if end of candidature or candidat have complete his application, else do nothin
                      else
                        $rootScope.redirectCandidatureIfClosedOrCompleted()

                'main_view.application_breadcrumb_view':
                    templateUrl: 'views/candidature/partials/navigation-breadcrumb.html',
                    controller: 'CandidatureBreadcrumbController'
      )
      # PAGE - FAQ
      $stateProvider.state('candidature.faq',
                url: '/frequently-asked-questions'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/faq.html',
                        controller: ($rootScope) ->
                          $rootScope.step.current = "faq"
      )
      # PAGE - Error
      $stateProvider.state('candidature.error',
                url: '/error'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/error.html',
                        controller: ($rootScope) ->
                          $rootScope.step.current = "error"
      )
      # PAGE - User Guide
      $stateProvider.state('candidature.user-guide',
                url: '/user-guide'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/user-guide.html',
                        controller: ($rootScope) ->
                          $rootScope.step.current = "guide"
      )
      # PAGE - Error ADMIN can't create application
      $stateProvider.state('candidature.error_admin_user',
                url: '/error_admin'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/error_admin.html',
      )
      # PAGE - CANDIDATURE - Expired
      $stateProvider.state('candidature.expired',
                url: '/expired'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/expired.html',
                        controller: ($rootScope) ->
                          $rootScope.step.current = "expired"
      )
      # PAGE - CANDIDATURE - en attente
      $stateProvider.state('candidature.pending',
                url: '/pending'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/pending.html',
                        controller: ($rootScope) ->
                          $rootScope.step.current = "pending"
      )
      # ACCOUNT
      $stateProvider.state('candidature.account',
                url: '/account'
                views:
                  'application_content_view':
                      templateUrl: 'views/candidature/account/index.html'

      )
      # ACCOUNT - Create Account
      $stateProvider.state('candidature.account.create-user',
                url: '/create'
                views:
                  'account_content_view':
                    templateUrl: 'views/candidature/account/04-creation.html'
                    controller: 'AccountCreationController'
      )
      # ACCOUNT - Create Account - Confirm page
      $stateProvider.state('candidature.account.user-created',
                url: '/confirmation'
                views:
                  'account_content_view':
                    templateUrl: 'views/candidature/account/05-creation-confirmation.html'
                    controller: 'AccountConfirmCreationController'
                params:
                    infos: null
      )
      # ACCOUNT- Create password
      $stateProvider.state('candidature.account.reset-password',
                url: '/reset-password/:token/:route'
                views:
                  'account_content_view':
                      templateUrl: 'views/candidature/account/06-password-creation.html'
                      controller: 'AccountCreatePasswordController'
      )
      # ACCOUNT - Ask for password change
      $stateProvider.state('candidature.account.password-forgot',
                url: '/password-forgot'
                views:
                  'account_content_view':
                      templateUrl: 'views/candidature/account/06-forgot-password.html'
                      controller: 'AccountPasswordResetController'
      )

      # ACCOUNT- login
      $stateProvider.state('candidature.account.login',
              url: '/login'
              views:
                'account_content_view':
                    templateUrl: 'views/candidature/account/07-connection.html'
                    controller: 'AccountLoginController'
      )

      # ONLINE CANDIDATURE - 02 - Terms of access
      $stateProvider.state('candidature.terms-of-access',
                  url: '/terms-of-access'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/02-terms-of-access.html',
                        controller: ($rootScope) ->
                          $rootScope.step.current = "02"
                          $rootScope.redirectCandidatureIfClosedOrCompleted() 
                          
      )
      # ONLINE CANDIDATURE - 03 - Terms of access
      $stateProvider.state('candidature.terms-of-access-2',
                  url: '/terms-of-access-suite'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/03-terms-of-access-2.html',
                        controller: ($rootScope) ->
                          $rootScope.step.current = "03"
                          $rootScope.redirectCandidatureIfClosedOrCompleted()
      )
      # ONLINE CANDIDATURE - 08 - Options
      $stateProvider.state('candidature.options',
                  url: '/options'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/08-inscription-options.html',
                        controller:"OptionsController"
      )
      # ONLINE CANDIDATURE - 09 - ADMINSISTRATIVE INFOS
      $stateProvider.state('candidature.administrative-informations',
                  url: '/administrative-informations'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/09-administrative-informations.html',
                        controller: "AdministrativeInformationsController"
      )
      # ONLINE CANDIDATURE - 10 - CONTACT INFOS
      $stateProvider.state('candidature.contact-informations',
                  url: '/contact-informations'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/10-contact-informations.html',
                        controller: "ContactInformationsController"
      )
      # ONLINE CANDIDATURE - 11 - LANGUAGES INFOS
      $stateProvider.state('candidature.spoken-languages',
                  url: '/languages'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/11-spoken-languages.html',
                        controller: "LanguagesInformationsController"
      )
      # ONLINE CANDIDATURE - 12 - PHOTOGRAPHY
      $stateProvider.state('candidature.photography',
                  url: '/photography'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/12-photography.html',
                        controller: "UploadUserPhotoController"
      )
      # ONLINE CANDIDATURE - 13 - Cursus
      $stateProvider.state('candidature.curiculum',
                  url: '/cursus'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/13-curiculum.html',
                        controller: ($rootScope) ->
                          $rootScope.loadInfos($rootScope)
                          $rootScope.step.current = "13"
                          $rootScope.current_display_screen = candidature_config.screen.cursus
      )
      # ONLINE CANDIDATURE - 14 - cv
      $stateProvider.state('candidature.cv',
                  url: '/cv'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/14-cv.html',
                        controller: "CvController"

      )
      # ONLINE CANDIDATURE - 15 - Parcours  Artistique
      $stateProvider.state('candidature.artistic-background',
                  url: '/artistics'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/15-artistic-background.html',
                        controller: "ArtisticBgController"

      )
      # ONLINE CANDIDATURE - 16 - Elements visuels
      $stateProvider.state('candidature.visual-elements',
                  url: '/video'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/16-visual-elements.html',
                        controller: "MediaVideoController"
      )
      # ONLINE CANDIDATURE - 17 - Candidatres precedents
      $stateProvider.state('candidature.previous-applications',
                  url: '/previous-applications'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/17-previous-applications.html',
                        controller: "PreviousAppController"
      )
      # ONLINE CANDIDATURE - 18 - Motivations
      $stateProvider.state('candidature.motivations',
                  url: '/motivations'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/18-motivations.html',
                        controller: ($rootScope) ->
                          $rootScope.loadInfos($rootScope)
                          $rootScope.step.current = "18"
      )
      # ONLINE CANDIDATURE - 19 - Projet 1
      $stateProvider.state('candidature.intentions-project-1',
                  url: '/project-1'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/19-intentions-project-1.html',
                        controller: ($rootScope, $scope, Users) ->
                          $rootScope.loadInfos($rootScope)
                          $rootScope.step.current = "19"
                          # binome list
                          Users.getList({artist__student_application__campaign__is_current_setup:"true"}).then((candidats) ->
                            $scope.application_users = []
                            for c in candidats                              
                              $scope.application_users.push({name:c.first_name + " " + c.last_name})
                          )

                            





      )
      # ONLINE CANDIDATURE - 20 - Projet 1
      $stateProvider.state('candidature.intentions-project-2',
                  url: '/project-2'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/20-intentions-project-2.html',
                        controller: ($rootScope) ->
                          $rootScope.loadInfos($rootScope)
                          $rootScope.step.current = "20"
      )

      # ONLINE CANDIDATURE - 22 - Doctorate
      $stateProvider.state('candidature.doctorate',
                  url: '/doctorate'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/21-doctorate.html',
                        controller: ($rootScope) ->
                          $rootScope.loadInfos($rootScope)
                          $rootScope.step.current = "21"
      )
      # ONLINE CANDIDATURE - 22 - Summary
      $stateProvider.state('candidature.summary',
                  url: '/summary'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/22-summary.html',
                        controller: ($rootScope) ->
                          $rootScope.loadInfos($rootScope)
                          $rootScope.step.current = "22"
      )
      # ONLINE CANDIDATURE - 23 - ITW
      $stateProvider.state('candidature.interview',
                  url: '/interview'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/23-interview.html',
                        controller: ($rootScope) ->
                          $rootScope.loadInfos($rootScope)
                          $rootScope.step.current = "23"

      )
      # ONLINE CANDIDATURE - 23 - Finalization
      $stateProvider.state('candidature.finalization',
                  url: '/finalization'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/24-finalization.html',
                        controller: "FinalizationAppController"
      )
        # ONLINE CANDIDATURE - 24 - Confirmation
      $stateProvider.state('candidature.confirmation',
                    url: '/confirmation'
                    views:
                      'application_content_view':
                          templateUrl: 'views/candidature/pages/25-confirmed.html',
                          controller: ($rootScope) ->
                            $rootScope.loadInfos($rootScope)
                            $rootScope.step.current = "25"
                      'application_breadcrumb_view':
                          # hide breadcrumb
                          template: '',

        )


])
