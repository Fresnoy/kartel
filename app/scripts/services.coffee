angular.module('memoire.services', ['restangular'])

# Services
.factory('Users', (Restangular) ->
        return Restangular.service('people/user/')
)

.factory('Artists', (Restangular) ->
        return Restangular.service('people/artist')
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

.factory('Partners', (Restangular) ->
        return Restangular.service('production/productionorganizationtask/')
)

.factory('Authentification', (Restangular) ->
        return Restangular.service('auth/')
)

# AME Service
.factory('AmeRestangular', (Restangular) ->

      # Restangular.setDefaultRequestParams({key: config.ame_key})
      #
      return Restangular.withConfig((RestangularConfigurer) ->
            RestangularConfigurer.setBaseUrl(config.ame_rest_uri);

            #RestangularConfigurer.defaultRequestParams.common.apikey = config.ame_key;
            RestangularConfigurer.setDefaultRequestParams({key: config.ame_key});
      )
)
