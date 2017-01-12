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
      url = "http://media.lefresnoy.net/?url=http://api.lefresnoy.net/{{ url }}&w={{ width }}&h={{ height }}&fmt=jpg"
      url = "{{ url }}"
      if scope.op
        url += "&op=#{ scope.op }"
      return "<img ng-src=\"#{url}\" />"
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
    controller: ($scope, $sce, Lightbox, Galleries, Media) ->

      gallery_id = $scope.gallery.match(/\d+$/)[0]
      $scope.gallery = Galleries.one(gallery_id).get().then((gallery) ->
        $scope.gallery = gallery
        for medium in gallery.media
          medium_id = medium.match(/\d+$/)[0]
          Media.one(medium_id).get().then((media) ->
            media_index = $scope.gallery.media.indexOf(media.url)

            media.isvideo = false
            if media.medium_url
              media.isvideo =  new RegExp("aml|youtube|vimeo|mp4","gi").test(media.medium_url);
              media.medium_url = $sce.trustAsResourceUrl(media.medium_url)

            $scope.gallery.media[media_index] = media
          )
      )


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
      scope.$watch(attr.ngModel, (value) ->
        scope.isUniqueUserField = (ctrl, value) ->
        if ctrl.toId
          clearTimeout(toId)
        ctrl.toId = setTimeout(() ->
          Users.getList({search: value}).then((data) ->
              ctrl.$setValidity('uniqueUserField', data.length==0);
          )
        , 200)
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
