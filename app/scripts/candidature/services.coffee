angular.module('candidature.services', ['restangular'])


.factory('VimeoToken', (RestangularV2) ->
        return RestangularV2.withConfig((RestangularConfigurer) ->
              # RestangularConfigurer.setBaseUrl(config.rest_uri_v2)
        ).service('assets/vimeo/upload/token')
)

.factory('Vimeo', (Restangular) ->
        return Restangular.withConfig((RestangularConfigurer) ->
              RestangularConfigurer.setBaseUrl(config.vimeo_rest_url)
              RestangularConfigurer.setFullResponse(true)
              # RestangularConfigurer.setDefaultHeaders({Authorization: "Bearer "+ localStorage.getItem('vimeo_upload_token')})
        )
)
