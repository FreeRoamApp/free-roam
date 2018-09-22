z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_flatten = require 'lodash/flatten'
_groupBy = require 'lodash/groupBy'
_isEmpty = require 'lodash/isEmpty'
_debounce = require 'lodash/debounce'
_some = require 'lodash/some'
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
      @addPlaces, optionalLayers, initialZoom, @isFilterBarHidden} = options

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

    @optionalLayers = _map optionalLayers, (optionalLayer) ->
      {
        optionalLayer
        $checkbox: new Checkbox()
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
    dataTypes = _map dataTypes, (options) ->
      {dataType, filters, isChecked, isCheckedSubject} = options
      isCheckedSubject ?= new RxBehaviorSubject isChecked
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
    groupedFilters = _groupBy filters, 'field'
    filter = _filter _map groupedFilters, (fieldFilters, field) ->
      unless _some fieldFilters, 'value'
        return

      filter = fieldFilters[0]

      switch filter.type
        when 'maxInt'
          {
            range:
              "#{field}":
                lte: filter.value
          }
        when 'minInt'
          {
            range:
              "#{field}":
                gte: filter.value
          }
        when 'maxIntSeasonal'
          {
            range:
              "#{field}.#{filter.value.season}":
                lte: filter.value.value
          }
        when 'maxIntDayNight'
          {
            range:
              "#{field}.#{filter.value.dayNight}":
                lte: filter.value.value
          }
        when 'cellSignal'
          {
            range:
              "#{field}.#{filter.value.carrier}.signal":
                gte: filter.value.signal
          }
        when 'booleanArray'
          arrayValues = _map _filter(fieldFilters, 'value'), 'arrayValue'
          {
            terms:
              "#{field}": arrayValues
              # minimum_should_match: 1
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

    z '.z-places-map-container',
      [
        unless @isFilterBarHidden
          [
            z '.filters',
              z '.filter.has-more', {
                onclick: =>
                  @state.set isTypesVisible: not isTypesVisible
              },
                @model.l.get 'placesMapContainer.show'
              _map filterTypes?[currentType], (filter) =>
                if filter.name
                  z '.filter', {
                    className: z.classKebab {
                      hasMore: filter.type isnt 'booleanArray'
                      hasValue: filter.value?
                    }
                    onclick: =>
                      if filter.type is 'booleanArray'
                        filter.valueSubject.next (not filter.value) or null
                      else
                        @showFilterDialog filter
                  }, filter.name
            z '.types', {
              className: z.classKebab {isVisible: isTypesVisible}
            },
              [
                _map types, ({dataType, $checkbox, isCheckedSubject, layer}) =>
                  z '.type', {
                    className: z.classKebab {
                      isSelected: currentType is dataType
                    }
                    onclick: =>
                      @state.set currentType: dataType
                      isCheckedSubject.next true
                  },
                    z '.checkbox', z $checkbox
                    z '.name', @model.l.get "placeTypes.#{dataType}"
                _map @optionalLayers, ({optionalLayer, $checkbox}) =>
                  {name, color, layer, insertBeneathLabels} = optionalLayer
                  z 'label.type', {
                    # TODO: figure out why debounce is necessary (2 clicks instead of 1)
                    onclick: _debounce =>
                      @$map.toggleLayer layer, {insertBeneathLabels}
                    , 100
                  },
                      z '.checkbox', z $checkbox
                      z '.name',
                        z '.key', {
                          style:
                            backgroundColor: color
                        }
                        name
              ]
          ]

        z @$map

        if place
          z @$placeTooltip
      ]
