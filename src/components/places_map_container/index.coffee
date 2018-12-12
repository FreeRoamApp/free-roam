z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_flatten = require 'lodash/flatten'
_reduce = require 'lodash/reduce'
_groupBy = require 'lodash/groupBy'
_sumBy = require 'lodash/sumBy'
_isEmpty = require 'lodash/isEmpty'
_some = require 'lodash/some'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'

Checkbox = require '../checkbox'
Map = require '../map'
PlaceTooltip = require '../place_tooltip'
PlacesFilterBar = require '../places_filter_bar'
PlacesSearch = require '../places_search'
Fab = require '../fab'
Tooltip = require '../tooltip'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep',
          'oct', 'nov', 'dec']

module.exports = class PlacesMapContainer
  constructor: (options) ->
    {@model, @router, @dataTypes, showScale, mapBoundsStreams,
      @persistentCookiePrefix, @addPlaces, @optionalLayers, @isSearchHidden,
      @limit, @sort, defaultOpacity, @currentDataType, initialCenter, center,
      initialZoom, zoom} = options

    mapBoundsStreams ?= new RxReplaySubject 1
    @sort ?= new RxBehaviorSubject undefined
    @limit ?= new RxBehaviorSubject null
    center ?= new RxBehaviorSubject null
    zoom ?= new RxBehaviorSubject null
    @currentDataType ?= new RxBehaviorSubject @dataTypes[0].dataType

    @persistentCookiePrefix ?= 'default'
    @addPlaces ?= RxObservable.of []

    zoomCookie = "#{@persistentCookiePrefix}_zoom"
    initialZoom ?= @model.cookie.get zoomCookie
    if initialZoom is 'undefined'
      initialZoom = undefined
    centerCookie = "#{@persistentCookiePrefix}_center"
    initialCenter ?= try
      JSON.parse @model.cookie.get centerCookie
    catch
      undefined

    @currentMapBounds = new RxBehaviorSubject null

    @dataTypesStream = @getDataTypesStreams @dataTypes

    @filterTypesStream = @getFilterTypesStream().publishReplay(1).refCount()
    placesWithCounts = RxObservable.combineLatest(
      @addPlaces, @getPlacesStream(), (vals...) -> vals
    ).map ([addPlaces, {places, visible, total}]) ->
      if places
        places = addPlaces.concat places
      else
        places = addPlaces

      {places, visible, total}
    .share() # otherwise map setsData twice (subscribe called twice)

    places = placesWithCounts
            .map ({places}) -> places
    counts = placesWithCounts.map ({visible, total}) -> {visible, total}
    @place = new RxBehaviorSubject null
    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null

    @isFilterTypesVisible = new RxBehaviorSubject false

    @$fab = new Fab()
    @$layersIcon = new Icon()
    @$tooltip = new Tooltip {
      @model
      key: 'mapLayers'
      offset:
        left: 60
    }

    persistentCookie = "#{@persistentCookiePrefix}_savedLayers"
    layersVisible = try
      JSON.parse @model.cookie.get persistentCookie
    catch
      []
    layersVisible or= []
    initialLayers = _map layersVisible, (layerId) =>
      optionalLayer = _find @optionalLayers, (optionalLayer) =>
        optionalLayer.layer.id is layerId

    @$map = new Map {
      @model, @router, places, @setFilterByField, showScale
      @place, @placePosition, @mapSize, mapBoundsStreams, @currentMapBounds
      defaultOpacity, initialCenter, center, initialZoom,  zoom,
      initialLayers
    }
    @$placeTooltip = new PlaceTooltip {
      @model, @router, @place, position: @placePosition, @mapSize
    }
    @$placesSearch = new PlacesSearch {
      @model, @router
      onclick: (location) =>
        if location.bbox and location.bbox[0] isnt location.bbox[2]
          mapBoundsStreams.next RxObservable.of {
            x1: location.bbox[0]
            y1: location.bbox[1]
            x2: location.bbox[2]
            y2: location.bbox[3]
          }
        else
          center.next [
            location.location.lat
            location.location.lon
          ]
          zoom.next 9
    }
    @$placesFilterBar = new PlacesFilterBar {
      @model, @isFilterTypesVisible, @currentDataType
    }

    @state = z.state
      filterTypes: @filterTypesStream
      dataTypes: @dataTypesStream
      visibleDataTypes: @dataTypesStream.map (dataTypes) ->
        _filter dataTypes, 'isChecked'
      currentDataType: @currentDataType
      place: @place
      counts: counts
      isLayersPickerVisible: false
      isFilterTypesVisible: @isFilterTypesVisible
      layersVisible: layersVisible

  afterMount: =>
    @disposable = @currentMapBounds.subscribe ({zoom, center} = {}) =>
      zoomCookie = "#{@persistentCookiePrefix}_zoom"
      @model.cookie.set zoomCookie, JSON.stringify zoom
      centerCookie = "#{@persistentCookiePrefix}_center"
      @model.cookie.set centerCookie, JSON.stringify center

  beforeUnmount: =>
    @disposable?.unsubscribe()
    @place.next null

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

      # if unchecking data type, set a new current
      {currentDataType} = @state.getValue()
      unless dataTypesWithValue[currentDataType]?.isChecked
        @currentDataType.next _find(dataTypesWithValue, 'isChecked')?.dataType

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

    streamValues = RxObservable.combineLatest(
      @filterTypesStream, @currentMapBounds, @dataTypesStream, @sort, @limit
      (vals...) -> vals
    )
    streamValues.switchMap (response) =>
      [filterTypes, currentMapBounds, dataTypes, sort, limit] = response

      boundsTooSmall = not currentMapBounds or Math.abs(
        currentMapBounds.bounds._ne.lat - currentMapBounds.bounds._sw.lat
      ) < 0.001

      if boundsTooSmall
        return RxObservable.of []

      RxObservable.combineLatest.apply null, _map dataTypes, ({dataType, isChecked}) =>
        unless isChecked
          return RxObservable.of []
        filters = filterTypes[dataType]
        queryFilter = @getQueryFilterFromFilters(
          filters, currentMapBounds?.bounds
        )


        @model[dataType].search {
          limit: limit
          sort: sort
          query:
            bool:
              filter: queryFilter
        }
      .map (responses) ->
        # visible = _sumBy responses, ({places}) -> places?.length
        total = _sumBy responses, 'total'
        places = _filter _map responses, 'places'
        places = _flatten places
        {
          visible: places.length
          total: total
          places: places
        }

  getQueryFilterFromFilters: (filters, currentMapBounds) ->
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
        when 'gtZero'
          {
            range:
              "#{field}":
                gt: 0
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
          ###
          alternative is:
          {terms: {"#{field}": arrayValues}, but terms
          is case-insensitive and 'contains', not 'equals'.
          breaks with camelcase restArea since it searches restarea
          ###
          {
            bool:
              should: _map arrayValues, (value) ->
                match:
                  "#{field}": value
            }

    filter.push {
      geo_bounding_box:
        location:
          top_left:
            lat: Math.round(1000 * currentMapBounds._ne.lat) / 1000
            lon: Math.round(1000 * currentMapBounds._sw.lng) / 1000
          bottom_right:
            lat: Math.round(1000 * currentMapBounds._sw.lat) / 1000
            lon: Math.round(1000 * currentMapBounds._ne.lng) / 1000
    }
    filter

  toggleLayer: (optionalLayer, index) =>
    {source, sourceId, layer, insertBeneathLabels} = optionalLayer
    {layersVisible} = @state.getValue()

    isVisible = index isnt -1

    if isVisible
      layersVisible.splice index, 1
    else
      ga? 'send', 'event', 'map', 'showLayer', layer.id
      layersVisible.push layer.id
    @state.set {layersVisible}

    persistentCookie = "#{@persistentCookiePrefix}_savedLayers"
    @model.cookie.set persistentCookie, JSON.stringify layersVisible

    @$map.toggleLayer layer, {
      insertBeneathLabels
      source: source
      sourceId: sourceId
    }


  render: =>
    {filterTypes, dataTypes, currentDataType, place, layersVisible, counts,
      visibleDataTypes, isFilterTypesVisible,
      isLayersPickerVisible} = @state.getValue()

    isCountsBarVisbile = counts?.visible < counts?.total

    z '.z-places-map-container', {
      onclick: =>
        if isLayersPickerVisible or isFilterTypesVisible
          @state.set isLayersPickerVisible: false
          @isFilterTypesVisible.next false
    },
      [
        unless @isSearchHidden
          z '.search',
            z @$placesSearch, {dataTypes}
            z @$placesFilterBar, {
              dataTypes, currentDataType, filterTypes, visibleDataTypes
            }
        z '.counts-bar', {
          className: z.classKebab {isVisible: isCountsBarVisbile}
        },
          @model.l.get 'placesMapContainer.countsBar', {
            replacements:
              visible: counts?.visible
              total: counts?.total
          }

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
                  color: colors.$bgText54
                }
                isImmediate: true
                onclick: =>
                  ga? 'send', 'event', 'map', 'showLayers'
                  @state.set isLayersPickerVisible: true
                  @$tooltip.close()

              # tooltip here. need easy way of adding this
              z @$tooltip, {
                $title: 'Show map layers'
                $content: 'Tap above to show satellite, public land, and cell coverage overlays'
              }


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
                        {name, layer} = optionalLayer
                        index = layersVisible.indexOf(layer.id)
                        isVisible = index isnt -1
                        z ".layer-icon.#{layer.id}.g-col.g-xs-4.g-md-4", {
                          className: z.classKebab {isVisible}
                          onclick: =>
                            @toggleLayer optionalLayer, index
                        },
                          z '.icon'
                          z '.name', name
      ]
