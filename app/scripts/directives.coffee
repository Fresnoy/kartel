# -*- tab-width: 2 -*-
"use strict"

angular.module('memoire.directives', ['memoire.services'])

.directive("fresnoyThumbnail", ->
  return {
    restrict: 'E',
    replace: true,
    scope: {
      url: '=thurl'
      width: '=thwidth'
      height: '=thheight'
    },
    template: '<img ng-src="http://media.lefresnoy.net/?url=http://api.lefresnoy.net/{{ url }}&w={{ width }}&h={{ height }}" />'
  }
)

.directive("fresnoyGallery", ->
  return {
    restrict: 'E',
    replace: true
    scope: {
      gallery: '='
    }
    templateUrl: "directives/gallery.html"
  }
)
