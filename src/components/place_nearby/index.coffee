z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_defaults = require 'lodash/defaults'
_map = require 'lodash/map'
_reduce = require 'lodash/reduce'
_filter = require 'lodash/filter'
_minBy = require 'lodash/minBy'
_maxBy = require 'lodash/maxBy'
_uniqBy = require 'lodash/uniqBy'

Fab = require '../fab'
Icon = require '../icon'
PlacesMapContainer = require '../places_map_container'
PlaceList = require '../place_list'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceNearby
  constructor: ({@model, @router, @place, @isActive}) ->
    nearestAmenities = @place.switchMap (place) =>
      unless place
        return RxObservable.of []
      @model[place.type].getNearestAmenitiesById place.id

    placeAndNearestAmenities = RxObservable.combineLatest(
      @place, nearestAmenities, (vals...) -> vals
    )

    addPlacesStreams = new RxReplaySubject 1
    addPlacesStreams.next(placeAndNearestAmenities
    .map ([place, nearestAmenities]) ->
      unless place
        return []
      _map _filter([place].concat nearestAmenities), (place) ->
        _defaults place, {iconOpacity: 1}
    )

    mapBoundsStreams = new RxReplaySubject 1
    mapBoundsStreams.next(
      placeAndNearestAmenities.map ([place, nearestAmenities]) =>
        unless place
          return RxObservable.of {}

        importantAmenities = _filter [place].concat nearestAmenities
        minX = _minBy importantAmenities, ({location}) -> location.lon
        minY = _minBy importantAmenities, ({location}) -> location.lat
        maxX = _maxBy importantAmenities, ({location}) -> location.lon
        maxY = _maxBy importantAmenities, ({location}) -> location.lat
        {
          x1: minX.location.lon
          y1: maxY.location.lat
          x2: maxX.location.lon
          y2: minY.location.lat
        }
    )

    @isCellTowersCheckedStreams = new RxReplaySubject 1
    @isCellTowersCheckedStreams.next RxObservable.of false

    @$fab = new Fab()
    @$addIcon = new Icon()

    @$placesMapContainer = new PlacesMapContainer {
      @model, @router, initialZoom: 9, defaultOpacity: 0.3
      showScale: true, addPlacesStreams, mapBoundsStreams, isSearchHidden: true
      sort: @place.map (place) ->
        unless place
          return undefined
        [
          _geo_distance:
            location:
              lat: place.location.lat
              lon: place.location.lon
            order: 'asc'
            unit: 'km'
            distance_type: 'plane'
        ]
      dataTypes: [
        {
          dataType: 'amenity'
          filters: @getAmenityFilters()
          defaultValue: true
        }
        {
          dataType: 'cellTower'
          filters: @getCellTowerFilters()
          isCheckedValueStreams: @isCellTowersCheckedStreams
        }
      ]
    }
    # TODO: better solution than @$placesMapContainer.getPlacesStream()?
    placesStream = @$placesMapContainer.getPlacesStream()
    placeAndNearestAmenitiesAndPlacesStream = RxObservable.combineLatest(
      @place, nearestAmenities, placesStream, (vals...) -> vals
    )
    @$placeList = new PlaceList {
      @model, @router
      places: placeAndNearestAmenitiesAndPlacesStream
      .map ([place, nearestAmenities, placesWithCounts]) ->
        places = placesWithCounts?.places
        knownDistances = _reduce place?.distanceTo, (obj, distanceTo) ->
          {id, time, distance} = distanceTo
          obj[id] = {time, distance}
          obj
        , {}

        places = _uniqBy (nearestAmenities or []).concat(places or []), 'id'
        places = _map places, (nearbyPlace) ->
          if knownDistance = knownDistances[nearbyPlace.id]
            _defaults {
              distance: knownDistance
            }, nearbyPlace
          else
            nearbyPlace
    }

    # don't fully load map to DOM / subscribe until user switches to this tab
    @isMapVisible = new RxBehaviorSubject false

    @state = z.state {
      isCellTowersChecked:
        @isCellTowersCheckedStreams.switch()
      @place
      @isMapVisible
    }

  beforeUnmount: =>
    @disposable.unsubscribe()
    @isMapVisible.next false

  afterMount: =>
    @disposable = @isActive.subscribe (isActive) =>
      if isActive and not @isMapVisible.getValue()
        @isMapVisible.next true


  getAmenityFilters: =>
    []

  getCellTowerFilters: =>
    []

  render: =>
    {isCellTowersChecked, place, isMapVisible} = @state.getValue()

    z '.z-place-nearby',
      z '.map', {
        ontouchstart: (e) -> e.stopPropagation()
        onmousedown: (e) -> e.stopPropagation()
      },
        if isMapVisible
          z @$placesMapContainer
        z '.toggle-cell-towers', {
          onclick: =>
            @isCellTowersCheckedStreams.next RxObservable.of not isCellTowersChecked
        },
          if isCellTowersChecked
            @model.l.get 'campgroundNearby.hideCellTowers'
          else
            @model.l.get 'campgroundNearby.showCellTowers'
      z '.place-list',
        z @$placeList, {hideRating: true}

      z '.fab',
        z @$fab,
          isPrimary: true
          icon: 'add'
          onclick: =>
            @router.go 'newAmenity', {}, {
              qs: {center: "#{place.location.lat},#{place.location.lon}"}
            }
