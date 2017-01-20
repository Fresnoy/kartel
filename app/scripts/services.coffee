angular.module('memoire.services', ['restangular'])

# Services
.factory('RestangularV2', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        )
)

.factory('Users', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('people/user')
)

.factory('Registration', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('people/user/register')
)

.factory('RestAuth', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('rest-auth')
)

.factory('Artists', (Restangular) ->
        return Restangular.service('people/artist')
)

.factory('ArtistsV2', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('people/artist')
)


.factory('Candidatures', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
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

.factory('Galleries', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('assets/gallery')
)

.factory('Media', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('assets/medium')
)

.factory('VimeoUpload', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('assets/vimeo/upload')
)

.factory('Partners', (Restangular) ->
        return Restangular.service('production/productionorganizationtask/')
)

.factory('Authentification', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('auth/')
)


# AME Service
.factory('AmeRestangular', (Restangular) ->
      return Restangular.withConfig((RestangularConfigurer) ->
            console.log("config.ame_rest_uri")
            console.log(config.ame_rest_uri)
            RestangularConfigurer.setBaseUrl(config.ame_rest_uri);
            RestangularConfigurer.setDefaultRequestParams({key: config.ame_key});
            RestangularConfigurer.setDefaultHeaders({'Content-Type': 'charset=UTF-8'})
      )
)
