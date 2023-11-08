angular.module('memoire.services', ['restangular'])

# Services
.factory('RestangularV2', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
            RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        )
)

.factory('Users', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('people/user')
)

.factory('RestAuth', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth')
)

.factory('Artists', (Restangular) ->
        return Restangular.service('people/artist')
)

.factory('ArtistsV2', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->

        ).service('people/artist')
)
.factory('WebsiteV2', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->

        ).service('common/website')
)

.factory('Candidatures', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->

        ).service('school/student-application')
)
.factory('AdminCandidatures', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->

        ).service('school/admin-student-application')
)

.factory('CandidatRegistration', (Restangular) ->
        # pas besoin d'un token - on le laisse en V1
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('school/student-application/user_register')
)

.factory('Campaigns', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('school/student-application-setup')
)

.factory('Students', (Restangular) ->
        return Restangular.service('school/student')
)

.factory('PromotionsV2', (RestangularV2) ->
        return RestangularV2.service('school/promotion')
)

.factory('Promotions', (Restangular) ->
        return Restangular.service('school/promotion')
)

.factory('Artworks', (Restangular) ->
        return Restangular.service('production/artwork')
)

.factory('Events', (Restangular) ->
        return Restangular.service('production/event')
)

.factory('Collaborators', (Restangular) ->
        return Restangular.service('production/productionstafftask/')
)

.factory('Galleries', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('assets/gallery')
)

.factory('Media', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('assets/medium')
)

.factory('Partners', (Restangular) ->
        return Restangular.service('production/productionorganizationtask/')
)

.factory('Authentification', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth')
)

.factory('Login', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth/login/')
)
.factory('Logout', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('rest-auth/logout/')
)


# AME Service
.factory('AmeRestangular', (Restangular) ->
      return Restangular.withConfig((RestangularConfigurer) ->
            RestangularConfigurer.setBaseUrl(config.ame_rest_uri);
            RestangularConfigurer.setDefaultRequestParams({key: config.ame_key});
            RestangularConfigurer.setDefaultHeaders({'Content-Type': 'charset=UTF-8'})
      )
)
