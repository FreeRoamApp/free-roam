z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_flatten = require 'lodash/flatten'
_reduce = require 'lodash/reduce'
_groupBy = require 'lodash/groupBy'
_isEmpty = require 'lodash/isEmpty'
_some = require 'lodash/some'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'

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
    {@model, @router, @dataTypes, showScale, mapBounds, @persistentCookiePrefix,
      @addPlaces, @optionalLayers, initialZoom, @isFilterBarHidden} = options

    @persistentCookiePrefix ?= 'default'
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

  beforeUnmount: =>
    @place.next null

  showFilterDialog: (filter) =>
    @model.overlay.open new FilterDialog {
      @model, @router, filter
    }

  getDataTypesStreams: (dataTypes) =>
    persistentCookie = "#{@persistentCookiePrefix}_savedDataTypes"
    savedDataTypes = try
      JSON.parse @model.cookie.get persistentCookie
    catch
      {}

    dataTypes = _map dataTypes, (options) ->
      {dataType, onclick, filters, defaultValue, isCheckedSubject} = options
      savedValue = savedDataTypes[dataType]
      isCheckedSubject ?= new RxBehaviorSubject(
        if savedValue? then savedValue else defaultValue
      )
      {
        dataType: dataType
        filters: filters
        onclick: onclick
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

      # set cookies to persist filters
      savedDataTypes = _reduce dataTypesWithValue, (obj, dataType) ->
        {dataType, isChecked} = dataType
        if isChecked?
          obj[dataType] = isChecked
        obj
      , {}
      @model.cookie.set persistentCookie, JSON.stringify savedDataTypes

      dataTypesWithValue

  getFilterTypesStream: =>
    persistentCookie = "#{@persistentCookiePrefix}_savedFilters"
    savedFilters = try
      JSON.parse @model.cookie.get persistentCookie
    catch
      {}
    filters = _flatten _map @dataTypes, ({dataType, filters}) ->
      _map filters, (filter) ->
        if filter.type is 'booleanArray'
          savedValueKey = "#{dataType}.#{filter.field}.#{filter.arrayValue}"
        else
          savedValueKey = "#{dataType}.#{filter.field}"
        savedValue = savedFilters[savedValueKey]
        _defaults {
          dataType: dataType
          valueSubject: new RxBehaviorSubject(
            if savedValue? then savedValue else filter.defaultValue
          )
        }, filter

    if _isEmpty filters
      return RxObservable.of {}

    RxObservable.combineLatest(
      _map filters, 'valueSubject'
      (vals...) -> vals
    )
    .map (values) =>
      filtersWithValue = _zipWith filters, values, (filter, value) ->
        _defaults {value}, filter

      # set cookie to persist filters
      savedFilters = _reduce filtersWithValue, (obj, filter) ->
        {dataType, field, value, type, arrayValue} = filter
        if value? and type is 'booleanArray'
          obj["#{dataType}.#{field}.#{arrayValue}"] = value
        else if value?
          obj["#{dataType}.#{field}"] = value
        obj
      , {}
      @model.cookie.set persistentCookie, JSON.stringify savedFilters

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
        when 'maxClearance'
          feet = parseInt filter.value.feet
          if isNaN feet
            feet = 0
          inches = parseInt filter.value.inches
          if isNaN inches
            feet = 0
          inches = feet * 12 + inches
          {
            range:
              heightInches:
                lt: inches
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
        when 'distanceTo'
          {
            range:
              "#{field}.#{filter.value.amenity}.time":
                lte: parseInt(filter.value.time)
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
                  unless isTypesVisible
                    ga? 'send', 'event', 'map', 'showTypes'
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
                        ga? 'send', 'event', 'map', 'filterClick', filter.field
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
              _map types, (type) =>
                {dataType, onclick, $checkbox, isCheckedSubject, layer} = type
                z '.type', {
                  className: z.classKebab {
                    isSelected: currentType is dataType
                    "#{dataType}": true
                  }
                  onclick: =>
                    ga? 'send', 'event', 'map', 'typeClick', dataType
                    onclick?()
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
          z @$placeTooltip
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
                  ga? 'send', 'event', 'map', 'showLayers'
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
                              ga? 'send', 'event', 'map', 'showLayer', layer.id
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
