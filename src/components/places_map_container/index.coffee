z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_flatten = require 'lodash/flatten'
_groupBy = require 'lodash/groupBy'
_isEmpty = require 'lodash/isEmpty'
_some = require 'lodash/some'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
require 'rxjs/add/observable/forkJoin'

Checkbox = require '../checkbox'
Map = require '../map'
PlaceTooltip = require '../place_tooltip'
FilterDialog = require '../filter_dialog'
Fab = require '../fab'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep',
          'oct', 'nov', 'dec']

module.exports = class PlacesMapContainer
  constructor: (options) ->
    {@model, @router, @dataTypes, showScale, mapBounds
      @addPlaces, @optionalLayers, initialZoom, @isFilterBarHidden} = options

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

    @$fab = new Fab()
    @$layersIcon = new Icon()
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
      isLayersPickerVisible: false
      layersVisible: []

  showFilterDialog: (filter) =>
    @model.overlay.open new FilterDialog {
      @model, @router, filter
    }

  getDataTypesStreams: (dataTypes) ->
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
    .map (values) ->
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
    .map (values) ->
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
          carrier = filter.value.carrier
          if filter.value.isLte
            {
              range:
                "#{field}.#{carrier}_lte.signal":
                  gte: filter.value.signal
            }
          else
            # check for lte and non lte
            bool:
              should: [
                {
                  range:
                    "#{field}.#{carrier}.signal":
                      gte: filter.value.signal
                }
                {
                  range:
                    "#{field}.#{carrier}_lte.signal":
                      gte: filter.value.signal
                }
              ]
        when 'weather'
          month = MONTHS[filter.value.month]
          {
            range:
              "#{field}.months.#{month}.#{filter.value.metric}":
                "#{filter.value.operator}": parseFloat(filter.value.number)
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
    {filterTypes, types, currentType, place, layersVisible,
      isTypesVisible, isLayersPickerVisible} = @state.getValue()

    z '.z-places-map-container', {
      onclick: =>
        if isLayersPickerVisible or isTypesVisible
          @state.set isLayersPickerVisible: false, isTypesVisible: false
    },
      [
        unless @isFilterBarHidden
          [
            z '.top-bar',
              z '.show', {
                onclick: =>
                  @state.set isTypesVisible: not isTypesVisible
              },
                @model.l.get 'placesMapContainer.show'
              z '.filters', {
                className: z.classKebab {"#{currentType}": true}
              },
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
              onclick: (e) ->
                e?.stopPropagation()
            },
              z '.title', @model.l.get 'placesMapContainer.typesTitle'
              _map types, ({dataType, $checkbox, isCheckedSubject, layer}) =>
                z '.type', {
                  className: z.classKebab {
                    isSelected: currentType is dataType
                    "#{dataType}": true
                  }
                  onclick: =>
                    @state.set currentType: dataType
                    isCheckedSubject.next true
                },
                  z '.checkbox', {
                    onclick: (e) ->
                      # if they're unchecking, don't switch to these filters
                      unless $checkbox.isChecked()
                        e.stopPropagation()
                  },
                    z $checkbox
                  z '.name', @model.l.get "placeTypes.#{dataType}"
          ]

        z '.map',
          z @$map
          z @$placeTooltip, {isVisible: Boolean place}
          unless _isEmpty @optionalLayers
            z '.layers-fab',
              z @$fab,
                colors:
                  c500: colors.$tertiary100
                  ripple: colors.$bgText70
                $icon: z @$layersIcon, {
                  icon: 'layers'
                  isTouchTarget: false
                  color: colors.$bgText70
                }
                isImmediate: true
                onclick: =>
                  @state.set isLayersPickerVisible: true

          z '.layers', {
            className: z.classKebab {isVisible: isLayersPickerVisible}
            onclick: (e) ->
              e?.stopPropagation()
          },
            z '.content',
              z '.title', @model.l.get 'placesMapContainer.layers'
              z '.layer-icons',
                z '.g-grid',
                  z '.g-cols',
                    if isLayersPickerVisible
                      _map @optionalLayers, (optionalLayer) =>
                        {name, source, layer, insertBeneathLabels} = optionalLayer
                        index = layersVisible.indexOf(layer.id)
                        isVisible = index isnt -1
                        z ".layer-icon.#{layer.id}.g-col.g-xs-4.g-md-4", {
                          className: z.classKebab {isVisible}
                          onclick: =>
                            if isVisible
                              layersVisible.splice index, 1
                            else
                              layersVisible.push layer.id
                            @state.set {layersVisible}

                            @$map.toggleLayer layer, {
                              insertBeneathLabels
                              source: source
                            }

                        },
                          z '.icon'
                          z '.name', name
      ]
