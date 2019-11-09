z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_zipWith = require 'lodash/zipWith'
_defaults = require 'lodash/defaults'
_find = require 'lodash/find'
_flatten = require 'lodash/flatten'
_reduce = require 'lodash/reduce'
_groupBy = require 'lodash/groupBy'
_some = require 'lodash/some'
_sumBy = require 'lodash/sumBy'
_isEqual = require 'lodash/isEqual'
_isEmpty = require 'lodash/isEmpty'
_uniq = require 'lodash/uniq'
_values = require 'lodash/values'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/distinctUntilChanged'
require 'rxjs/add/observable/of'

Toggle = require '../toggle'
PlaceSheet = require '../place_sheet'
LayerSettingsOverlay = require '../layer_settings_overlay'
Map = require '../map'
PlacesFilterBar = require '../places_filter_bar'
PlacesFiltersOverlay = require '../places_filters_overlay'
PlacesSearch = require '../places_search'
Fab = require '../fab'
TooltipPositioner = require '../tooltip_positioner'
Icon = require '../icon'
MapService = require '../../services/map'
TripService = require '../../services/trip'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesMapContainer
  constructor: (options) ->
    {@model, @router, isShell, @trip, @tripRoute, isEditingRoute,
      editRouteWaypoints, @dataTypes, showScale, destinations, @routes,
      mapBoundsStreams, @persistentCookiePrefix, @addPlacesStreams,
      @limit, @sort, defaultOpacity, @currentDataType, @initialDataTypes,
      @initialFilters, initialCenter, center, initialZoom, zoom, donut,
      selectedRoute, searchQuery, @isSearchHidden} = options

    mapBoundsStreams ?= new RxReplaySubject 1
    @sort ?= new RxBehaviorSubject undefined
    @limit ?= new RxBehaviorSubject null
    center ?= new RxBehaviorSubject null
    zoom ?= new RxBehaviorSubject null
    unless @currentDataType
      @currentDataType = new RxReplaySubject 1
      @currentDataType.next RxObservable.of @dataTypes[0].dataType
    @initialDataTypes ?= new RxBehaviorSubject null
    @initialFilters ?= new RxBehaviorSubject null

    @persistentCookiePrefix ?= 'default'
    unless @addPlacesStreams
      @addPlacesStreams = new RxReplaySubject 1
      @addPlacesStreams.next RxObservable.of []

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

    @isFilterTypesVisible = new RxBehaviorSubject false
    @isLegendVisible = new RxBehaviorSubject false

    @dataTypesStream = @getDataTypesStreams @dataTypes

    @isTripFilterEnabled = new RxBehaviorSubject Boolean @trip

    @filterTypesStream = @getFilterTypesStream()
    placesStream = @getPlacesStream()
    placesWithCounts = RxObservable.combineLatest(
      @addPlacesStreams.switch()
      placesStream
      (vals...) -> vals
    ).map ([addPlaces, {places, visible, total}]) ->
      places ?= []
      places = places.concat (addPlaces or []) # addPlaces should "under" places on map

      {places, visible, total}
    .share() # otherwise map setsData twice (subscribe called twice)

    places = placesWithCounts
            .map ({places}) ->
              places
    counts = placesWithCounts.map ({visible, total}) -> {visible, total}

    placesAndIsLegendVisible = RxObservable.combineLatest(
      places, @isLegendVisible, (vals...) -> vals
    )

    @place = new RxBehaviorSubject null
    @coordinate = new RxBehaviorSubject null
    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null
    @$fab = new Fab()
    @$layersIcon = new Icon()
    @$layerSettingsIcon = new Icon()
    @$tooltip = new TooltipPositioner {
      @model
      key: 'mapLayers'
      offset:
        left: 60
    }

    @optionalLayers = MapService.getOptionalLayers {
      @model, @place, @placePosition
    }

    persistentCookie = "#{@persistentCookiePrefix}_savedLayers"
    layersVisible = try
      JSON.parse @model.cookie.get persistentCookie
    catch
      []
    layersVisible or= []
    @layersVisible = new RxBehaviorSubject layersVisible
    initialLayers = _filter _map layersVisible, (layerId) =>
      optionalLayer = @setOpacityByOptionalLayer @optionalLayers[layerId]

    @$map = new Map {
      @model, @router, places, @setFilterByField, showScale
      @place, @placePosition, @mapSize, mapBoundsStreams, @currentMapBounds
      @coordinate, defaultOpacity, initialCenter, center, initialZoom,  zoom,
      initialLayers, @routes, selectedRoute, donut
      beforeMapClickFn: =>
        {isLayersPickerVisible} = @state.getValue()
        # if layers picker is visible, cancel the normal map click
        # but still allow clicking on places
        Boolean not isLayersPickerVisible
    }
    @$placeSheet = new PlaceSheet {
      @model, @router, @place, @trip, @tripRoute, isEditingRoute,
      editRouteWaypoints, @coordinate, @addOptionalLayer, @layersVisible
      @addLayerById, @removeLayerById
    }
    @isPlaceFiltersVisible = new RxBehaviorSubject false
    @$placesSearch = new PlacesSearch {
      @model, @router, searchQuery, isAppBar: true, hasDirectPlaceLinks: true
      @dataTypesStream
      @filterTypesStream
      onclick: ({location, bbox, text}) =>
        @addPlacesStreams.next RxObservable.of [{
          location: location
          name: text or @model.l.get 'placesMapContainer.yourSearchQuery'
          icon: 'search'
          type: 'coordinate'
        }]
        mapBoundsStreams.next RxObservable.of bbox
    }
    @$placeFiltersOverlay = new PlacesFiltersOverlay {
      @model, @router, @dataTypesStream, @filterTypesStream
      isVisible: @isPlaceFiltersVisible
    }
    @$placesFilterBar = new PlacesFilterBar {
      @model, @isFilterTypesVisible, @currentDataType
      @dataTypesStream, @filterTypesStream
      @tripRoute, @isTripFilterEnabled
      @isPlaceFiltersVisible
    }

    @state = z.state
      isShell: isShell
      filterTypes: @filterTypesStream
      dataTypes: @dataTypesStream
      visibleDataTypes: @dataTypesStream.map (dataTypes) ->
        _filter dataTypes, 'isChecked'
      currentDataType: @currentDataType.switch()
      place: @place
      icons: placesAndIsLegendVisible.map ([places, isLegendVisible]) ->
        if isLegendVisible
          _filter _uniq _map places, 'icon'
      counts: counts
      isLayersPickerVisible: false
      isLegendVisible: @isLegendVisible
      isFilterTypesVisible: @isFilterTypesVisible
      layersVisible: @layersVisible
      tripRoute: @tripRoute

  afterMount: =>
    @disposable = @currentMapBounds.subscribe ({zoom, center} = {}) =>
      if zoom
        zoomCookie = "#{@persistentCookiePrefix}_zoom"
        @model.cookie.set zoomCookie, JSON.stringify zoom
        @$map.setInitialZoom zoom # for when map is re-opened
      if center
        centerCookie = "#{@persistentCookiePrefix}_center"
        @model.cookie.set centerCookie, JSON.stringify center
        @$map.setInitialCenter center # for when map is re-opened

  beforeUnmount: =>
    @disposable?.unsubscribe()
    @place.next null

  getDataTypesStreams: (dataTypes) =>
    persistentCookie = "#{@persistentCookiePrefix}_savedDataTypes"
    savedDataTypes = try
      JSON.parse @model.cookie.get persistentCookie
    catch
      {}

    # FIXME: rm after 2/21/2019
    unless _some savedDataTypes
      savedDataTypes = {}

    dataTypes = _map dataTypes, (options) =>
      {dataType, onclick, filters, defaultValue,
        getIconFn, isCheckedValueStreams} = options
      savedValue = savedDataTypes[dataType]
      isCheckedValueStreams ?= new RxReplaySubject 1
      isCheckedValueStreams.next @initialDataTypes.map (initialDataTypes) ->
        if initialDataTypes then initialDataTypes.indexOf(dataType) isnt -1
        else if savedValue? then savedValue
        else defaultValue
      {
        dataType: dataType
        filters: filters
        onclick: onclick
        getIconFn: getIconFn
        isCheckedValueStreams: isCheckedValueStreams
        $toggle: new Toggle {isSelectedStreams: isCheckedValueStreams}
      }

    RxObservable.combineLatest(
      _map dataTypes, ({isCheckedValueStreams}) ->
        isCheckedValueStreams.switch()
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

      if _some savedDataTypes
        @model.cookie.set persistentCookie, JSON.stringify savedDataTypes

      # if unchecking data type, set a new current
      {currentDataType} = @state.getValue()
      unless dataTypesWithValue[currentDataType]?.isChecked
        @currentDataType.next RxObservable.of _find(dataTypesWithValue, 'isChecked')?.dataType

      dataTypesWithValue
    .publishReplay(1).refCount()

  getFilterTypesStream: =>
    @initialFilters.switchMap (initialFilters) =>
      persistentCookie = "#{@persistentCookiePrefix}_savedFilters"
      savedFilters = try
        JSON.parse @model.cookie.get persistentCookie
      catch
        {}
      # TODO: can we only map over visible dataTypes?
      filters = _flatten _map @dataTypes, ({dataType, filters}) =>
        _map filters, (filter) =>
          if filter.type is 'booleanArray'
            savedValueKey = "#{dataType}.#{filter.field}.#{filter.arrayValue}"
          else
            savedValueKey = "#{dataType}.#{filter.field}"

          if initialFilters
            initialValue = initialFilters[savedValueKey]
          else
            initialValue = savedFilters[savedValueKey]

          valueStreams = new RxReplaySubject 1
          valueStreams.next RxObservable.of(
            if initialValue? then initialValue else filter.defaultValue
          )

          _defaults {dataType, valueStreams}, filter

      if _isEmpty filters
        return RxObservable.of {}

      RxObservable.combineLatest(
        _map filters, ({valueStreams}) -> valueStreams.switch()
        (vals...) -> vals
      )
      # ^^ updates a lot since $filterContent sets valueStreams on a lot
      # on load. this prevents a bunch of extra lodash loops from getting called
      .distinctUntilChanged _isEqual
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

    # for whatever reason, required for stream to update, unless the
    # initialFilters switchMap is removed
    .publishReplay(1).refCount()

  getPlacesStream: =>
    unless window?
      return RxObservable.of []

    streamValues = RxObservable.combineLatest(
      @filterTypesStream, @currentMapBounds, @dataTypesStream
      @sort, @limit, @isTripFilterEnabled
      @trip or RxObservable.of null
      @tripRoute or RxObservable.of null
      (
        @routes?.map (routes) ->
          _find(routes, ({routeSlug}) -> routeSlug)?.routeSlug
      ) or RxObservable.of null
      (vals...) -> vals
    )
    streamValues.switchMap (response) =>
      [
        filterTypes, currentMapBounds, dataTypes, sort, limit,
        isTripFilterEnabled, trip, tripRoute, tripAltRouteSlug
      ] = response

      boundsTooSmall = not currentMapBounds or Math.abs(
        currentMapBounds.bounds._ne.lat - currentMapBounds.bounds._sw.lat
      ) < 0.0005

      if boundsTooSmall
        # RxObservable.of [] will make a place's icon disappear when zoomed max
        # RxObservable.never keeps what's there
        return RxObservable.never()

      RxObservable.combineLatest.apply null, _map dataTypes, ({dataType, isChecked, getIconFn}) =>
        unless isChecked
          return RxObservable.of []
        filters = filterTypes[dataType]
        queryFilter = MapService.getESQueryFromFilters(
          filters, currentMapBounds?.bounds
        )

        @model[dataType].search {
          limit: limit
          sort: sort
          tripId: if isTripFilterEnabled then trip?.id
          tripRouteId: if isTripFilterEnabled then tripRoute?.routeId
          tripAltRouteSlug: tripAltRouteSlug
          query:
            bool:
              filter: queryFilter
        }
        .map (response) ->
          # TODO: is there a more efficient way to do this?
          # so we're not mapping over places too much?
          iconFn = getIconFn? filters
          response.places = _map response.places, (place) ->
            place.icon = iconFn? place
            place
          response

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

  addOptionalLayer: (optionalLayer) =>
    if optionalLayer
      @optionalLayers[optionalLayer.layer.id] = optionalLayer

  setOpacityByOptionalLayer: (optionalLayer) ->
    unless optionalLayer # for temporary layers like mvums
      return
    layerId = optionalLayer.layer.id
    layerSettings = JSON.parse localStorage?.layerSettings or '{}'
    if optionalLayer.layer.type is 'fill' and typeof optionalLayer.layer.paint['fill-opacity'] isnt 'object'
      optionalLayer.layer.paint['fill-opacity'] = layerSettings[layerId]?.opacity or optionalLayer.defaultOpacity or 1
    else if typeof optionalLayer.layer.paint['fill-opacity'] isnt 'object'
      optionalLayer.layer.paint['raster-opacity'] = layerSettings[layerId]?.opacity or optionalLayer.defaultOpacity or 1
    optionalLayer


  addLayerById: (layerId, {skipSave} = {}) =>
    optionalLayer = @optionalLayers[layerId]
    optionalLayer = @setOpacityByOptionalLayer optionalLayer

    @$map.addLayer optionalLayer

    {layersVisible} = @state.getValue()
    ga? 'send', 'event', 'map', 'showLayer', layerId
    layersVisible.push layerId
    @layersVisible.next layersVisible

    unless optionalLayer.isTemporary
      persistentCookie = "#{@persistentCookiePrefix}_savedLayers"
      @model.cookie.set persistentCookie, JSON.stringify layersVisible


  removeLayerById: (layerId) =>
    optionalLayer = @optionalLayers[layerId]
    @$map.removeLayerById layerId

    {layersVisible} = @state.getValue()
    index = layersVisible.indexOf(layerId)
    layersVisible.splice index, 1
    @layersVisible.next layersVisible

    unless optionalLayer.isTemporary
      persistentCookie = "#{@persistentCookiePrefix}_savedLayers"
      @model.cookie.set persistentCookie, JSON.stringify layersVisible


  render: =>
    {isShell, currentDataType, place, layersVisible,
      counts, visibleDataTypes, isFilterTypesVisible, isLegendVisible, icons,
      isLayersPickerVisible, tripRoute} = @state.getValue()

    isCountsBarVisbile = counts?.visible < counts?.total

    z '.z-places-map-container', {
      className: z.classKebab {isShell}
      onclick: =>
        if isLayersPickerVisible or isFilterTypesVisible or isLegendVisible
          @state.set isLayersPickerVisible: false
          @isLegendVisible.next false
          @isFilterTypesVisible.next false
    },
      [
        unless @isSearchHidden
          z '.search',
            z @$placesSearch
            z @$placesFilterBar, {
              currentDataType, visibleDataTypes
              @trip, @isTripFilterEnabled
            }
            z @$placeFiltersOverlay
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
          z @$placeSheet

          z '.legend-fab', {
            onclick: =>
              @isLegendVisible.next true
          },
            @model.l.get 'placesMapContainer.legend'

          z '.legend', {
            className: z.classKebab {isVisible: isLegendVisible}
          },
            _map icons, (icon) =>
              z '.item',
                z 'img.icon',
                  src: if isLegendVisible \
                       then "#{config.CDN_URL}/maps/sprite_svgs/#{icon}.svg"
                z '.name', @model.l.get "mapLegend.#{icon}"

          unless _isEmpty @optionalLayers
            z '.layers-fab',
              z @$fab,
                icon: 'layers'
                colors:
                  cText: colors.$bgText54
                isImmediate: true
                onclick: =>
                  ga? 'send', 'event', 'map', 'showLayers'
                  @state.set isLayersPickerVisible: true
                  @$tooltip.close()

              z @$tooltip


          z '.layers', {
            className: z.classKebab {isVisible: isLayersPickerVisible}
            onclick: (e) ->
              e?.stopPropagation()
          },
            z '.content',
              z '.top',
                z '.title', @model.l.get 'placesMapContainer.layers'
                z '.settings',
                  z @$layerSettingsIcon,
                    icon: 'settings'
                    color: colors.$bgText87
                    isTouchTarget: false
                    size: '18px'
                    onclick: =>
                      @model.overlay.open new LayerSettingsOverlay {
                        @model, @optionalLayers
                        setLayerOpacityById: @$map.setLayerOpacityById
                      }
              z '.layer-icons',
                z '.g-grid',
                  z '.g-cols',
                    if isLayersPickerVisible
                      _map @optionalLayers, (optionalLayer) =>
                        {name, layer} = optionalLayer
                        index = layersVisible.indexOf(layer.id)
                        isVisible = index isnt -1
                        z ".layer-icon.g-col.g-xs-4.g-md-4", {
                          className: z.classKebab {isVisible}
                          onclick: =>
                            if isVisible
                              @removeLayerById layer.id
                            else
                              @addLayerById layer.id
                        },
                          z '.icon',
                            style:
                              backgroundImage: "url(#{optionalLayer.thumb})"
                          z '.name', name
      ]
