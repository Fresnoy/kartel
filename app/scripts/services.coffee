angular.module('memoire.services', ['restangular'])

# Services
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
