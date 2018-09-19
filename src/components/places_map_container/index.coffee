z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_flatten = require 'lodash/flatten'
_groupBy = require 'lodash/groupBy'
_isEmpty = require 'lodash/isEmpty'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/forkJoin'

Checkbox = require '../../components/checkbox'
Map = require '../../components/map'
PlaceTooltip = require '../../components/place_tooltip'
FilterDialog = require '../../components/filter_dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesMapContainer
  constructor: (options) ->
    {@model, @router, @overlay$, @dataTypes, showScale, mapBounds
      @addPlaces, initialZoom} = options

    @addPlaces ?= RxObservable.of []

    @dataTypesStream = @getDataTypesStreams @dataTypes

    @currentLocation = new RxBehaviorSubject null
    @filterTypesStream = @getFilterTypesStream().publishReplay(1).refCount()
    places = RxObservable.combineLatest(
      @addPlaces, @getPlacesStream(), (vals...) -> vals
    ).map ([addPlaces, places]) ->
      if places
        addPlaces.concat places
      else
        addPlaces
    @place = new RxBehaviorSubject null
    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null

    @$map = new Map {
      @model, @router, places, @setFilterByField, initialZoom, showScale
      @place, @placePosition, @mapSize, mapBounds, @currentLocation
    }
    @$placeTooltip = new PlaceTooltip {
      @model, @router, @place, position: @placePosition, @mapSize
    }

    @state = z.state
      filterTypes: @filterTypesStream
      types: @dataTypesStream
      currentType: @dataTypes[0].dataType
      place: @place
      isTypesVisible: false

  showFilterDialog: (filter) =>
    @overlay$.next new FilterDialog {
      @model, @router, @overlay$, filter
    }

  getDataTypesStreams: (dataTypes) =>
    dataTypes = _map dataTypes, ({dataType, filters, isChecked}) ->
      isCheckedSubject = new RxBehaviorSubject isChecked
      {
        dataType: dataType
        filters: filters
        isCheckedSubject: isCheckedSubject
        $checkbox: new Checkbox {value: isCheckedSubject}
      }

    RxObservable.combineLatest(
      _map dataTypes, 'isCheckedSubject'
      (vals...) -> vals
    )
    .map (values) =>
      dataTypesWithValue = _zipWith dataTypes, values, (dataType, isChecked) ->
        _defaults {isChecked}, dataType

  getFilterTypesStream: =>
    filters = _flatten _map @dataTypes, ({dataType, filters}) ->
      _map filters, (filter) -> _defaults {dataType}, filter

    if _isEmpty filters
      return RxObservable.of {}

    RxObservable.combineLatest(
      _map filters, 'valueSubject'
      (vals...) -> vals
    )
    .map (values) =>
      filtersWithValue = _zipWith filters, values, (filter, value) ->
        _defaults {value}, filter
      _groupBy filtersWithValue, 'dataType'

  getPlacesStream: =>
    unless window?
      return RxObservable.of []

    filterTypesAndCurrentLocationAndDataTypes = RxObservable.combineLatest(
      @filterTypesStream, @currentLocation, @dataTypesStream, (vals...) -> vals
    )
    filterTypesAndCurrentLocationAndDataTypes.switchMap (response) =>
      [filterTypes, currentLocation, dataTypes] = response
      if not currentLocation
        return RxObservable.of []

      RxObservable.combineLatest.apply null, _map dataTypes, ({dataType, isChecked}) =>
        unless isChecked
          return RxObservable.of []
        filters = filterTypes[dataType]
        queryFilter = @getQueryFilterFromFilters filters, currentLocation

        @model[dataType].search {
          query:
            bool:
              filter: queryFilter
        }
      .map (values) ->
        _flatten values

  getQueryFilterFromFilters: (filters, currentLocation) ->
    filter = _filter _map filters, (filter) ->
      unless filter.value
        return
      switch filter.type
        when 'maxInt'
          {
            range:
              "#{filter.field}":
                lte: filter.value
          }
        when 'minInt'
          {
            range:
              "#{filter.field}":
                gte: filter.value
          }
        when 'maxIntSeasonal'
          {
            range:
              "#{filter.field}.#{filter.value.season}":
                lte: filter.value.value
          }
        when 'maxIntDayNight'
          {
            range:
              "#{filter.field}.#{filter.value.dayNight}":
                lte: filter.value.value
          }
        when 'cellSignal'
          {
            range:
              "#{filter.field}.#{filter.value.carrier}.signal":
                gte: filter.value.signal

          }

    filter.push {
      geo_bounding_box:
        location:
          top_left:
            lat: currentLocation._ne.lat
            lon: currentLocation._sw.lng
          bottom_right:
            lat: currentLocation._sw.lat
            lon: currentLocation._ne.lng
    }
    filter

  render: =>
    {filterTypes, types, currentType, place, isTypesVisible} = @state.getValue()

    console.log 'filterTypes', filterTypes, currentType

    z '.z-places-map-container',
      z '.filters',
        z '.filter', {
          onclick: =>
            @state.set isTypesVisible: not isTypesVisible
        },
          @model.l.get 'placesMapContainer.types'
        _map filterTypes?[currentType], (filter) =>
          if filter.name
            z '.filter', {
              className: z.classKebab {
                hasMore: true, hasValue: filter.value?
              }
              onclick: =>
                @showFilterDialog filter
            }, filter.name
      z '.types', {
        className: z.classKebab {isVisible: isTypesVisible}
      },
        _map types, ({dataType, $checkbox, isCheckedSubject}) =>
          z '.type', {
            onclick: =>
              @state.set currentType: dataType
              isCheckedSubject.next true
          },
            z '.checkbox',
              z $checkbox
            z '.name', @model.l.get "placeTypes.#{dataType}"

      z @$map

      if place
        z @$placeTooltip
