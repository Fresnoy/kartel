angular.module('memoire.services', ['restangular'])

# Services
.factory('RestangularV2', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
            RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        )
)

.factory('Users', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('people/user')
)

.factory('Registration', (Restangular) ->
        # pas besoin d'un token - on le laisse en V1
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('people/user/register')
)

.factory('RestAuth', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('rest-auth')
)

.factory('Artists', (Restangular) ->
        return Restangular.service('people/artist')
)

.factory('ArtistsV2', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('people/artist')
)

.factory('Candidatures', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('school/student-application')
)

.factory('Students', (Restangular) ->
        return Restangular.service('school/student')
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
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('assets/gallery')
)

.factory('Media', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('assets/medium')
)


.factory('Partners', (Restangular) ->
        return Restangular.service('production/productionorganizationtask/')
)

.factory('Authentification', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('rest-auth')
)

.factory('Login', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('rest-auth/login/')
)
.factory('Logout', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
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
