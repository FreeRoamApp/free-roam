z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_find = require 'lodash/find'

AppBar = require '../app_bar'
ButtonBack = require '../button_back'
Fab = require '../fab'
Icon = require '../icon'
Map = require '../map'
PlacesSearch = require '../places_search'
CheckInTooltip = require '../check_in_tooltip'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class CoordinatePicker
  constructor: (options) ->
    {@model, @router, @onPick, @pickButtonText
      center, initialZoom} = options

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@router}

    @places = new RxBehaviorSubject []
    @mapCenter = new RxBehaviorSubject center
    initialZoom ?= 4

    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null
    @$checkInTooltip = new CheckInTooltip {
      @model, @router, position: @placePosition, @mapSize
      place: @places.map (places) -> places?[0]
      onSave: =>
        @onPick arguments...
        .then =>
          @model.overlay.close()

    }
    @$placesSearch = new PlacesSearch {
      @model, @router
      onclick: (location) =>
        @placePosition.next @$map.map.project location.location
        @places.next [{
          name: location.text
          slug: location.slug or ''
          id: location.sourceId
          type: location.sourceType
          location: location.location
        }]
    }

    @$myLocationFab = new Fab()
    @$locationIcon = new Icon()

    @$map = new Map {
      @model, @router, @places, @mapSize, center: @mapCenter, initialZoom
      hideControls: true
      onclick: (e) =>
        lat = Math.round(10000 * e.lngLat.lat) / 10000
        lon = Math.round(10000 * e.lngLat.lng) / 10000
        coordinates = "#{lat}, #{lon}"
        @placePosition.next e.point

        @places.next [{
          name: coordinates
          slug: ''
          type: 'coordinate'
          location:
            lon: e.lngLat.lng
            lat: e.lngLat.lat
        }]
    }

    @state = z.state {
      isSatelliteVisible: false
    }

  toggleSatellite: =>
    {isSatelliteVisible} = @state.getValue()

    layers = MapService.getOptionalLayers {@model}
    {layer, source, sourceId, insertBeneathLabels} = _find layers, (layer) ->
      layer.layer.id is 'satellite'

    @state.set isSatelliteVisible: not isSatelliteVisible
    @$map.toggleLayer layer, {
      insertBeneathLabels
      source: source
      sourceId: sourceId
    }

  render: =>
    {isSatelliteVisible} = @state.getValue()

    z '.z-coordinate-picker',
      z @$appBar, {
        title: @model.l.get 'coordinatePicker.title'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
          onclick: =>
            @model.overlay.close()
        }
      }
      z '.map',
        z '.search',
          z @$placesSearch
        z @$checkInTooltip,
          buttonText: @pickButtonText or @model.l.get 'general.select'
        z '.toggle-satellite', {
          onclick: @toggleSatellite
        },
          if isSatelliteVisible
            @model.l.get 'coordinatePicker.hideSatellite'
          else
            @model.l.get 'coordinatePicker.showSatellite'
        if navigator?.geolocation
          z '.my-location-fab',
            z @$myLocationFab,
              colors:
                c500: colors.$tertiary0
              $icon: z @$locationIcon, {
                icon: 'crosshair'
                isTouchTarget: false
                color: colors.$secondary500
              }
              isImmediate: true
              onclick: =>
                navigator.geolocation.getCurrentPosition (pos) =>
                  lat = Math.round(10000 * pos.coords.latitude) / 10000
                  lon = Math.round(10000 * pos.coords.longitude) / 10000
                  coordinates = "#{lat}, #{lon}"
                  @mapCenter.next [lon, lat]
                  @placePosition.next @$map.map.project {lon, lat}
                  @places.next [{
                    name: coordinates
                    slug: ''
                    type: 'coordinate'
                    location:
                      lon: lon
                      lat: lat
                  }]
        z @$map
