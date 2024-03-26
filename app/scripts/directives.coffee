# -*- tab-width: 2 -*-
"use strict"

angular.module('memoire.directives', ['memoire.services', 'bootstrapLightbox'])

.directive("fresnoyThumbnail", ->
  return {
    restrict: 'E',
    replace: true,
    scope: {
      url: '=thurl'
      width: '=thwidth'
      height: '=thheight'
      op: '='
    },
    template: (x, scope) ->
      url = "{{ url_image }}&w={{ width }}&h={{ height }}&exif=1&fmt=jpg"
      return "<img ng-src=\"#{url}\" />"
    controller: ($scope) ->
      $scope.$watch("url", (value) ->
          if(value)
            if(value.indexOf('http') == -1)
              $scope.url_image = config.media_service+"?url="+config.api_url+value+"&w="+$scope.width+"h="+$scope.height+"&fmt=jpg"
            else
              $scope.url_image = config.media_service+"?url="+value+"&w="+$scope.width+"h="+$scope.height+"&fmt=jpg"
            console.log($scope.url_image)
            if $scope.op
              $scope.url_image += "&op=#{ scope.op }"
      )

  }
)

.directive("fresnoyAuthors", ->
  return {
    restrict: 'E',
    replace: false,
    scope: {
      authors: '=authors'
    },
    template: (x, scope) ->
      # return "<span>\"#{name}\"</span>"
      return "<span >{{name}}</span>"
    controller: ($scope) ->
      $scope.$watch("authors", (value) ->
          $scope.name = ""
          if(value)
            name = ""
            for author in value
              name+= if author.nickname then author.nickname else author.user.first_name + " " + author.user.last_name
          $scope.name = name
      )

  }
)


.config((LightboxProvider) ->
  LightboxProvider.templateUrl = 'directives/fresnoyGallery-lightbox-modal.html'
)


.directive("fresnoyGallery", ->
  return {
    restrict: 'E',
    replace: true,
    transclude: true,
    scope: {
      gallery: '='
      openLightboxModal: '&'
    }
    templateUrl: "directives/gallery.html"
    controller: ($scope, $sce, Lightbox) ->

      for media in $scope.gallery.media
        media.isvideo = false
        url = media.medium_url
        if url
          media.isvideo = new RegExp("aml|youtube|vimeo|mp4","gi").test(url)
          media.iframe = /(\.pdf|vimeo\.com|youtube\.com|youtu\.be)/i.test(url)
          media.original = url
          # embed video youtube
          url = url.replace(/^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?/gm, 
                          'https://www.youtube.com/embed/$5?rel=0');
          # embed video vimeo
          url = url.replace(/^https?:\/\/(?:www\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/([^\/]*)\/videos\/|album\/(\d+)\/video\/|)(\d+)(?:$|\/|\?)(.*)/g, 
                            "https://player.vimeo.com/video/$3?h=$4&quality=1080p")
          # when url is image set picture var, otherwise set medium_url
          if(/\.(jpe?g|png|gif|bmp|tif)/i.test(url))
              media.picture = url
          media.medium_url = $sce.trustAsResourceUrl(url)
          # media.isvideo =  new RegExp("aml|youtube|vimeo|mp4","gi").test(media.medium_url);
          # media.medium_url = $sce.trustAsResourceUrl(media.medium_url)


      $scope.openLightboxModal = (index) ->

        Lightbox.openModal($scope.gallery.media, index)
  }
)

.directive("flagIcon", ->
  return {
    restrict: 'E',
    replace: true,
    scope: {
      country: '='
    }
    template: (x, scope) ->
      return '<img class="flag" ng-src="images/flags/' + scope.country + '.png" alt="{{ country }}"/>'
  }
)

.directive('uniqueUserField', (Users) ->
  toId = null
  return {
    restrict: 'A',
    require: 'ngModel',
    link: (scope, elem, attr, ctrl) ->
      scope.isUniqueUserField = (ctrl, value) ->
        if ctrl.toId
          clearTimeout(toId)
        ctrl.toId = setTimeout(() ->
          if(!value)
            return
          Users.getList({search: value}).then((data) ->
              ctrl.$setValidity('uniqueUserField', data.length<1)
          )
        , 200)
      scope.$watch(attr.ngModel, (value, value2) ->
        scope.isUniqueUserField(ctrl, value)
      )
  }
)

.directive('sameValueAs', () ->
    return {
        require: "ngModel",
        scope: {
            otherModelValue: "=sameValueAs"
        },
        link: (scope, element, attributes, ngModel) ->
            ngModel.$validators.sameValueAs = (modelValue) ->
                return modelValue == scope.otherModelValue

            scope.$watch(scope.otherModelValue, (value) ->
                ngModel.$validate();
            )
    }
)
