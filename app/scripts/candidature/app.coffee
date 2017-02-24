# -*- tab-width: 2 -*-
"use strict"

angular.module('candidature.application', ['candidature.controllers',
            'ui.router',
])
.config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider,
                                                                      $stateProvider,
                                                                      $urlRouterProvider) ->
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
                'main_view':
                  templateUrl: 'views/candidature/index.html'
                  controller: 'ParentCandidatureController'

                'main_view.application_content_view':
                    templateUrl: 'views/candidature/pages/00-landing.html',
                    controller: 'IntroController'

                'main_view.application_step_view':
                    templateUrl: 'views/candidature/partials/step-infos.html'
                #
                # 'main_view.application_account_view':
                #     templateUrl: 'views/candidature/account/account-status.html'
                #     controller: 'AccountBarController'
      )
      # FAQ
      $stateProvider.state('candidature.faq',
                url: '/frequently-asked-questions'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/faq.html',
      )
      # Error
      $stateProvider.state('candidature.error',
                url: '/error'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/error.html',


      )
      # Error ADMIN
      $stateProvider.state('candidature.error_admin_user',
                url: '/error_admin'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/error_admin.html',


      )
      # Expired
      $stateProvider.state('candidature.expired',
                url: '/expired'
                views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/expired.html',


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


      $stateProvider.state('candidature.account.init-password-with-token',
                url: '/init-password/:token/:route'
                views:
                  'account_content_view':
                      templateUrl: 'views/candidature/account/init_password.html'
                      controller: 'AccountChangePasswordController'
      )


      # Create User
      $stateProvider.state('candidature.account.create-user',
                url: '/create'
                views:
                  'account_content_view':
                    templateUrl: 'views/candidature/account/create.html'
                    controller: 'CreateAccountController'
      )

      # Candidature 02 - Choose type of candidature
      $stateProvider.state('candidature.option',
                  url: '/option'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/02-option.html',
                        controller: ($rootScope) -> $rootScope.loadInfos($rootScope)
        )

        # Candidature 03 - Choose type of candidature
      $stateProvider.state('candidature.personnal-infos',
                    url: '/personnnal-infos'
                    views:
                      'application_content_view':
                          templateUrl: 'views/candidature/pages/03-personnal_infos.html',
                          controller: 'PersonnalInfosController'
      )



      # Candidature 04 - cursus
      $stateProvider.state('candidature.cursus',
                url: '/cursus'
                views:
                  'application_content_view':
                      templateUrl: 'views/candidature/pages/04-cursus.html'
                      controller: 'CursusController'

      )

      # Candidature 05 - documents
      $stateProvider.state('candidature.documents',
                url: '/documents'
                views:
                  'application_content_view':
                      templateUrl: 'views/candidature/pages/05-docs.html'
                      controller: 'MediaController'

      )
      # Candidature 06 - Messages / entretiens
      $stateProvider.state('candidature.messages',
                  url: '/messages'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/06-messages.html'
                        controller: 'MessageController'

      )

      # Candidature 07 - finalisation / confiramtion
      $stateProvider.state('candidature.finalization',
                  url: '/confirmation'
                  views:
                    'application_content_view':
                        templateUrl: 'views/candidature/pages/07-validation-finale.html'
                        controller: 'FinalizationController'
                  requiresLogin: true
      )

      # Candidature FIN - completed
      $stateProvider.state('candidature.completed',
                url: '/completed'
                views:
                  'application_content_view':
                      templateUrl: 'views/candidature/pages/08-completed.html'
                      controller: 'CompletedController'
                requiresLogin: true

      )
])
