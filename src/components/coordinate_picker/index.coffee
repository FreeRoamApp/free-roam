z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_find = require 'lodash/find'

Fab = require '../fab'
Icon = require '../icon'
Map = require '../map'
PlacesSearch = require '../places_search'
CheckInTooltip = require '../check_in_tooltip'
MapService = require '../../services/map'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class CoordinatePickerOverlay
  constructor: (options) ->
    {@model, @router, @onPick, @pickButtonText
      center, initialZoom, @isPlacesOnly} = options

    @currentMapBounds = new RxBehaviorSubject null
    @place = new RxBehaviorSubject null
    @places = RxObservable.combineLatest(
      @currentMapBounds
      @place
    ).switchMap ([currentMapBounds, place]) =>
      boundsTooSmall = not currentMapBounds or Math.abs(
        currentMapBounds.bounds._ne.lat - currentMapBounds.bounds._sw.lat
      ) < 0.001

      (if boundsTooSmall or currentMapBounds.zoom < 7
        RxObservable.of {places: []}
      else
        queryFilter = MapService.getESQueryFromFilters(
          filters = [], currentMapBounds?.bounds
        )

        @model.campground.search {
          limit: 50
          # sort: sort
          includeId: true
          query:
            bool:
              filter: queryFilter
        }
      ).map ({count, places}) ->
        if place?.type is 'coordinate'
          [place].concat places
        else
          places


    @mapCenter = new RxBehaviorSubject center
    mapBoundsStreams = new RxReplaySubject 1
    @zoom = new RxBehaviorSubject null
    initialZoom ?= 4

    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null

    @$checkInTooltip = new CheckInTooltip {
      @model, @router, position: @placePosition, @mapSize
      place: @place
      onSave: =>
        @onPick arguments...
        .then =>
          @model.overlay.close()
    }
    @$placesSearch = new PlacesSearch {
      @model, @router
      onclick: (place) =>
        mapBoundsStreams.next RxObservable.of place.bbox
        @placePosition.next @$map.map.project place.location
        if place.sourceType in ['overnight', 'campground'] or not @isPlacesOnly
          @place.next {
            name: place.text
            slug: place.slug or ''
            id: place.sourceId
            type: place.sourceType
            location: place.location
          }
    }

    @$myLocationFab = new Fab()
    @$locationIcon = new Icon()

    @$map = new Map {
      @model, @router, @places, @mapSize, center: @mapCenter, initialZoom, @zoom
      @place, @placePosition
      @currentMapBounds, mapBoundsStreams
      hideControls: true
      onclick: (e) =>
        if e.features?[0]?.properties?.name
          coordinates = e.features[0].geometry.coordinates.slice()
          while Math.abs(e.lngLat.lng - (coordinates[0])) > 180
            coordinates[0] += if e.lngLat.lng > coordinates[0] then 360 else -360
          @placePosition.next @$map.map.project coordinates
          @place.next {
            name: e.features[0].properties.name
            slug: e.features[0].properties.slug
            id: e.features[0].properties.id
            type: e.features[0].properties.type
            location:
              lon: e.lngLat.lng
              lat: e.lngLat.lat
          }
        else if not @isPlacesOnly
          lat = Math.round(10000 * e.lngLat.lat) / 10000
          lon = Math.round(10000 * e.lngLat.lng) / 10000
          coordinatesStr = "#{lat}, #{lon}"
          @placePosition.next e.point
          @place.next {
            name: coordinatesStr
            slug: ''
            type: 'coordinate'
            location:
              lon: e.lngLat.lng
              lat: e.lngLat.lat
          }
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
              isSecondary: true
              icon: 'crosshair'
              isImmediate: true
              onclick: =>
                MapService.getLocation()
                .then ({lat, lon}) =>
                  coordinates = "#{lat}, #{lon}"
                  @mapCenter.next [lon, lat]
                  @zoom.next 8
                  unless @isPlacesOnly
                    @placePosition.next @$map.map.project {lon, lat}
                    @place.next {
                      name: coordinates
                      slug: ''
                      type: 'coordinate'
                      location:
                        lon: lon
                        lat: lat
                    }
        z @$map
