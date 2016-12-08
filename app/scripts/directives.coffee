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
    controller: ($scope, $sce, Lightbox) ->
      for media in $scope.gallery.media
        media.isvideo = false
        if media.medium_url
          media.isvideo =  new RegExp("aml|youtube|vimeo|mp4","gi").test(media.medium_url);
          media.medium_url = $sce.trustAsResourceUrl(media.medium_url)


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

.directive('uniqueUsername', (UserSearch) ->
  toId = null
  return {
    restrict: 'A',
    require: 'ngModel',
    link: (scope, elem, attr, ctrl) ->
      scope.$watch(attr.ngModel, (value) ->
        if toId
          clearTimeout(toId);
        userName = {'username': value}
        toId = setTimeout(() ->
          # call to some API that returns { user: user } or { user: false }
          UserSearch.post(userName).then((data) ->
              ctrl.$setValidity('uniqueUsername', !data);
          )
        , 200)
      )
  }
)
