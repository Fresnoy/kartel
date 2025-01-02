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
.factory('Students', (Restangular) ->
        return Restangular.service('school/student')
)
# used !
.factory('Candidatures', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
        ).service('school/student-application')
)



# CANDIDATURES 
.factory('APIK', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
                RestangularConfigurer.setBaseUrl(config.kandidatur_api_url)
                if localStorage.getItem('Candidaturestoken')
                    RestangularConfigurer.setDefaultHeaders({Authorization: "JWT "+ localStorage.getItem('Candidaturestoken')});
        )
)

.factory('APIV2K', (APIK) ->
        return APIK.withConfig((RestangularConfigurer) ->
                RestangularConfigurer.setBaseUrl(config.kandidatur_api_url+"v2/")
        )
)

.factory('LoginK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('rest-auth/login/')
)
.factory('LogoutK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('rest-auth/logout/')
)

.factory('CandidaturesK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('school/student-application')
)

.factory('AdminCandidaturesK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('school/admin-student-application')
)
.factory('UsersK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('people/user')
)
.factory('ArtistsK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('people/artist')
)
.factory('GalleriesK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('asset/gallery')
)
.factory('MediaK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('asset/medium')
)
.factory('WebsiteK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        ).service('common/website')
)
.factory('CampaignsK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        )
        .service('school/student-application-setup')
)
.factory('PromotionsK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
        )
        .service('school/promotion')
)
.factory('VimeoTokenK', (APIV2K) ->
        return APIV2K.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('assets/vimeo/upload/token')
)
.factory('GraphqlK', (APIK) ->
        return APIK.withConfig((RestangularConfigurer) ->
        ).service('graphql')
)


# Externals APIS 
.factory('Vimeo', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.vimeo_rest_url)
              RestangularConfigurer.setFullResponse(true)
              # RestangularConfigurer.setDefaultHeaders({Authorization: "Bearer "+ localStorage.getItem('vimeo_upload_token')})
        )
)

.factory('CandidaturesAnalytics', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
                RestangularConfigurer.setBaseUrl(config.analytics_live_api.url)
        ).service(config.analytics_live_api.param)
)



# AME Service
.factory('AmeRestangular', (Restangular) ->
      return Restangular.withConfig((RestangularConfigurer) ->
            RestangularConfigurer.setBaseUrl(config.ame_rest_uri);
            RestangularConfigurer.setDefaultRequestParams({key: config.ame_key});
            RestangularConfigurer.setDefaultHeaders({'Content-Type': 'charset=UTF-8'})
      )
)

# GraphQL Service

.factory('Graphql', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
                RestangularConfigurer.setBaseUrl(config.api_url);
        ).service('graphql')
)
