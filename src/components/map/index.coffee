z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_findIndex = require 'lodash/findIndex'
_flatten = require 'lodash/flatten'
_forEach = require 'lodash/forEach'
_orderBy = require 'lodash/orderBy'

tile = require './tilejson'
Spinner = require '../spinner'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Map
  type: 'Widget'

  constructor: (options) ->
    {@model, @router, @places, @showScale, @mapBoundsStreams, @currentMapBounds
      @place, @coordinate, @placePosition, @mapSize, @initialZoom, @zoom,
      @initialCenter, @initialBounds, @route, @fill, @initialLayers, @center,
      @defaultOpacity, @onclick, @preserveDrawingBuffer, @onContentReady,
      @hideLabels, @hideControls, @usePlaceNumbers,
      @beforeMapClickFn} = options

    @place ?= new RxBehaviorSubject null
    @coordinate ?= new RxBehaviorSubject null
    @defaultOpacity ?= 1

    @initialZoom ?= 4
    @initialCenter ?= [-105.894, 40.048]

    @savedLayers = @initialLayers or []
    @visibleLayers = []
    @$spinner = new Spinner()

    @state = z.state
      isLoading: true
      place: @place
      windowSize: @model.window.getSize()

  getClosestPixelRatio: ->
    if window.devicePixelRatio > 1.5 then 2 else 1

  getBeforeLayer: (zIndex = 0) =>
    layers = @map?.getStyle().layers
    # Find the index of the first symbol layer in the map style
    # also use layer zIndexes to keep certain layers always on top of others
    beforeLayer = undefined
    i = 0
    while i < layers.length
      if layers[i].type is 'symbol' or layers[i]?.metadata?.zIndex
        beforeLayer = layers[i].id
        if not layers[i].metadata?.zIndex or layers[i].metadata.zIndex > zIndex
          break
      i += 1
    return beforeLayer

  setLayerOpacityById: (id, opacity) =>
    layer = @map.getLayer id
    if layer
      if layer.type is 'fill'
        @map.setPaintProperty id, 'fill-opacity', opacity
      else
        @map.setPaintProperty id, 'raster-opacity', opacity

  addLayer: (optionalLayer) =>
    {layer, source, sourceId, insertBeneathLabels, onclick} = optionalLayer

    if @getLayerIndexById(layer.id) is -1
      @visibleLayers.push optionalLayer
      layerId = if insertBeneathLabels then @getBeforeLayer(layer.metadata?.zIndex) else undefined
      try
        @map.addSource sourceId or layer.id, source
      catch err
        console.log 'source exists...', err
      @map.addLayer layer, layerId

  getLayerIndexById: (id) ->
    _findIndex(@visibleLayers, ({layer}) -> layer.id is id)

  removeLayerById: (id) =>
    index = @getLayerIndexById id
    if index isnt -1
      @visibleLayers.splice index, 1
    # layer = @map.getLayer id
    @map.removeLayer id
    # source = layer.source
    # @map.removeSource source

  toggleLayer: (layer) =>
    if @getLayerIndexById(layer.layer.id) is -1
      @addLayer layer
    else
      @removeLayerById layer.layer.id

  getBlob: =>
    new Promise (resolve) =>
      @map.getCanvas().toBlob resolve

  initializeMap: ($$el) =>
    @$$mapEl = $$el.querySelector('.map')

    @model.additionalScript.add(
      'css', "#{config.SCRIPTS_CDN_URL}/mapbox-gl-1.0.0.css"
    )
    @model.additionalScript.add(
      'js', "#{config.SCRIPTS_CDN_URL}/mapbox-gl-1.0.0.js"
    )
    .then =>
      console.log '%cNEW MAPBOX MAP', 'color: red'
      mapboxgl.accessToken = config.MAPBOX_ACCESS_TOKEN
      @map = new mapboxgl.Map {
        container: @$$mapEl
        style: tile
        center: @initialCenter
        zoom: @initialZoom
        bounds: @initialBounds
        preserveDrawingBuffer: @preserveDrawingBuffer
      }
      @map.dragRotate.disable()
      @map.touchZoomRotate.disableRotation()

  addPlacesLayer: =>
    @map.addSource 'places', {
      type: 'geojson'
      data:
        type: 'FeatureCollection'
        features: []
    }
    if @usePlaceNumbers
      @map.addLayer {
        id: 'places'
        type: 'symbol'
        source: 'places'
        layout:
          'icon-image': 'empty'
          'icon-allow-overlap': true
          'icon-ignore-placement': true
          'icon-size': 1
          'icon-anchor': 'bottom'
          'text-field': '{number}'
          'text-anchor': 'bottom'
          'text-size': 9
          'text-font': ['Open Sans Bold'] # must exist in tilejson

        paint:
          'text-translate': [0, -9]
          'text-color': '#ffffff'
      }
    else
      # two separate layers because mapbox is kind of buggy with all in one
      # layer. main problem is icon-allow-overlap: false gets rid of the
      # nice fading in and out. once fixed, try having in same layer again?
      # https://github.com/mapbox/mapbox-gl-js/issues/6052
      @map.addLayer {
        id: 'places-text'
        type: 'symbol'
        source: 'places'
        minzoom: 8
        layout:
          'text-field': '{name}'

          'text-ignore-placement': false
          'text-allow-overlap': false
          'text-anchor': 'bottom-left'
          'text-font': ['Open Sans Regular'] # must exist in tilejson
          'text-size': 12
        paint:
          'text-opacity': ['get', 'iconOpacity']
          'text-translate': [12, -4]
          'text-halo-color': 'rgba(255, 255, 255, 1)'
          'text-halo-width': 2
      }
      @map.addLayer {
        id: 'places'
        type: 'symbol'
        source: 'places'
        layout:
          'icon-image': '{icon}' # uses spritesheet defined in tilejson.coffee

          # one of these needs to be on or all icons won't show.
          # if icon-allow-overlap is true, fading in/out doesn't work
          # 'icon-allow-overlap': true
          'icon-ignore-placement': true

          'icon-size': 1
          'icon-anchor': 'bottom'

        paint:
          'icon-opacity': ['get', 'iconOpacity']
      }

  addRouteLayers: =>
    @map.addSource 'route', {
      type: 'geojson'
      data:
        type: 'Feature'
        properties: {}
        geometry:
          type: 'LineString'
          coordinates: []
    }
    @map.addLayer {
      id: 'route'
      type: 'line'
      source: 'route'
      layout:
        'line-join': 'round'
        'line-cap': 'round'
      paint:
        'line-color': colors.getRawColor(colors.$primary500)
        'line-width': 2
    }
    @map.addLayer {
      id: 'route-direction'
      type: 'symbol'
      source: 'route'
      layout:
        'symbol-placement': 'line'
        'symbol-spacing': 100
        'icon-allow-overlap': true
        'icon-image': 'arrow'
        'icon-size': 1
        visibility: 'visible'
    }

  # TODO: might be better to just handle this in calling component (trip),
  # but would need to handle for shareMap too
  addFillLayer: =>
    # FIXME: custom sourceId, custom onclick, color, opacity
    @map.addSource 'fill', {
      type: 'geojson'
      data: {
        type: 'FeatureCollection'
        features: []
      }
    }
    @map.addLayer {
      id: 'fill'
      type: 'fill'
      source: 'fill'
      layout: {}
      paint:
        'fill-color': colors.getRawColor colors.$primary500
        'fill-opacity': 0.1
    }
  afterMount: ($$el) =>
    @state.set isLoading: true
    @initializeMap $$el
    .then =>
      @map.on 'load', =>
        console.log 'map loaded'

        @subscribeToResize()

        if @hideLabels
          @_hideLabels()

        if @fill
          @addFillLayer()
          @subscribeToFill()

        if @route
          @addRouteLayers()
          @subscribeToRoute()

        @addPlacesLayer()

        @addSavedLayers()

        @updateMapLocation()
        if @mapBoundsStreams
          @subscribeToMapBounds()
        @subscribeToPlaces()
        @subscribeToCenter()
        @subscribeToZoom()
        @state.set isLoading: false



        if @onContentReady
          Promise.all [
            @places?.take(1).toPromise() or Promise.resolve null
            @routes?.take(1).toPromise() or Promise.resolve null
          ]
          .then =>
            # give it a second to draw. better solution is:
            # https://github.com/mapbox/mapbox-gl-js/issues/4904
            setTimeout @onContentReady, 1000

      @map.on 'move', @onMapMove
      @map.on 'moveend', @updateMapLocation

      if not @hideLabels and not @hideControls
        @map.addControl new mapboxgl.GeolocateControl({
          positionOptions:
            enableHighAccuracy: true
          trackUserLocation: true
        }), 'bottom-left'

      if @showScale
        @map.addControl new mapboxgl.ScaleControl {
          maxWidth: 100
          unit: 'imperial'
        }

      if @onclick
        @map.on 'click', @onclick
        @map.on 'click', 'places', (e) =>
          e.originalEvent.stopPropagation()
          @onclick e
        @map.on 'click', 'places-text', (e) =>
          e.originalEvent.stopPropagation()
          @onclick e
      else
        console.log 'listen ctx'
        @map.on 'click', (e) =>
          e.originalEvent.preventDefault()

          if @beforeMapClickFn and @beforeMapClickFn() is false
            return

          if @place.getValue()
            return @place.next null

          coordinateValue = @coordinate.getValue()

          if coordinateValue
            @coordinate.next null # already open, close

          # don't 'click' on double-tap zoom
          if @clickTimeout
            clearTimeout @clickTimeout
            @clickTimeout = null
            return

          @clickTimeout = setTimeout =>
            @clickTimeout = null
            if e.originalEvent.isPropagationStopped
              return

            # @place.next null

            unless coordinateValue
              @coordinate.next null # reset the tooltip for things like elevation
              latRounded = Math.round(e.lngLat.lat * 10000) / 10000
              lonRounded = Math.round(e.lngLat.lng * 10000) / 10000

              @coordinate.next {
                name: "#{latRounded}, #{lonRounded}"
                type: 'coordinate'
                position: e.point
                location: [e.lngLat.lng, e.lngLat.lat]
                features:
                  _filter @map.queryRenderedFeatures(e.point), (feature) ->
                    feature.source in [
                      'us-usfs', 'us-blm', 'fire-weather'
                    ]
              }
          , 300

        onclick = (e) =>
          e.originalEvent.isPropagationStopped = true

          if e.features[0].properties.type is 'coordinate'
            return

          @coordinate.next null

          coordinates = e.features[0].geometry.coordinates.slice()
          name = e.features[0].properties.name
          number = e.features[0].properties.number
          description = e.features[0].properties.description
          id = e.features[0].properties.id
          slug = e.features[0].properties.slug
          type = e.features[0].properties.type
          rating = if e.features[0].properties.rating is 'null' \
                   then 0
                   else e.features[0].properties.rating
          thumbnailPrefix = e.features[0].properties.thumbnailPrefix
          # Ensure that if the map is zoomed out such that multiple
          # copies of the feature are visible, the popup appears
          # over the copy being pointed to.
          while Math.abs(e.lngLat.lng - (coordinates[0])) > 180
            coordinates[0] += if e.lngLat.lng > coordinates[0] then 360 else -360
          position = @map.project coordinates
          @placePosition.next position
          @place.next {
            id: id
            slug: slug
            type: type
            name: name
            description: description
            rating: rating
            thumbnailPrefix: thumbnailPrefix
            position: position
            location: coordinates
          }
        @map.on 'click', 'places', onclick
        @map.on 'click', 'places-text', onclick

      # Change the cursor to a pointer when the mouse is over the places layer.
      onmouseenter = =>
        @map.getCanvas().style.cursor = 'pointer'
      @map.on 'mouseenter', 'places', onmouseenter
      @map.on 'mouseenter', 'places-text', onmouseenter

      # Change it back to a pointer when it leaves.
      onmouseleave = =>
        @map.getCanvas().style.cursor = ''
      @map.on 'mouseleave', 'places', onmouseleave
      @map.on 'mouseleave', 'places-text', onmouseleave

  beforeUnmount: =>
    console.log 'rm subscription'
    @disposable?.unsubscribe()
    @routeDisposable?.unsubscribe()
    @fillDisposable?.unsubscribe()
    @mapBoundsStreamsDisposable?.unsubscribe()
    @centerDisposable?.unsubscribe()
    @zoomDisposable?.unsubscribe()
    @resizeSubscription?.unsubscribe()
    @savedLayers = @visibleLayers
    @visibleLayers = []
    @map?.remove()
    @map = null

  _hideLabels: =>
    _forEach @map.style.stylesheet.layers, (layer) =>
      if layer.type is 'symbol'
        @map.removeLayer layer.id

  addSavedLayers: =>
    _map @savedLayers, @addLayer

  subscribeToResize: =>
    setTimeout =>
      checkIsReady = =>
        if @$$mapEl and @$$mapEl.offsetWidth
          @resizeSubscription = @model.window.getSize().subscribe =>
            setTimeout =>
              @map?.resize()
              @mapSize?.next {
                width: @$$mapEl.offsetWidth, height: @$$mapEl.offsetHeight
              }
            , 0
        else
          setTimeout checkIsReady, 100
      checkIsReady()
    , 0 # give time for re-render...

  subscribeToMapBounds: =>
    @mapBoundsStreamsDisposable = @mapBoundsStreams.switch()
    .subscribe ({x1, y1, x2, y2} = {}) =>
      if x1?
        @map.fitBounds(
          [[x1, y1], [x2, y2]]
          {
            duration: 0 # no animation
            padding:
              top: 100
              left: 10
              right: 100
              bottom: 10
          }
        )

  subscribeToCenter: =>
    @centerDisposable = @center?.subscribe (longLatArray) =>
      if longLatArray
        @map.setCenter longLatArray

  subscribeToZoom: =>
    @zoomDisposable = @zoom?.subscribe (zoom) =>
      if zoom
        @map.setZoom zoom

  subscribeToRoute: =>
    console.log 'create subscription'
    @routeDisposable = @route.subscribe (route) =>
      unless route?.legs
        return
      geojson = _flatten _map route.legs, ({shape}) ->
        MapService.decodePolyline shape
      @map.getSource('route')?.setData {
        type: 'Feature'
        properties: {}
        geometry:
          type: 'LineString'
          coordinates: geojson
      }

  subscribeToFill: =>
    @fillDisposable = @fill.subscribe (fill) =>
      @map.getSource('fill')?.setData fill

  subscribeToPlaces: =>
    console.log 'create subscription'
    placesAndCoordinate = RxObservable.combineLatest(
      @places, @coordinate, (vals...) -> vals
    )
    @disposable = placesAndCoordinate.subscribe ([places, coordinate]) =>
      if coordinate
        baseArr = [
          {
            type: 'Feature'
            properties:
              name: coordinate.name
              icon: 'drop_pin'
              iconOpacity: @defaultOpacity
              type: 'coordinate'
            geometry:
              type: 'Point'
              coordinates: coordinate.location
          }
        ]
      else
        baseArr = []

      @map.getSource('places')?.setData {
        type: 'FeatureCollection'
        features: baseArr.concat _map places, (place, i) =>
          {
            type: 'Feature'
            properties:
              name: place.name
              number: "#{i + 1}"
              id: place.id
              slug: place.slug
              rating: place.rating
              description: place.description
              thumbnailPrefix: place.thumbnailPrefix
              type: place.type
              icon: place.icon or 'default'
              iconOpacity: place.iconOpacity or @defaultOpacity
            geometry:
              type: 'Point'
              coordinates: [ # reverse of typical lat, lon
                place.location.lon
                place.location.lat
              ]
          }
      }

  # update tooltip pos
  onMapMove: =>
    {place} = @state.getValue()
    if place?.location
      @placePosition.next @map.project place.location

  updateMapLocation: =>
    @currentMapBounds?.next {
      bounds: @map.getBounds()
      center: @map.getCenter()
      zoom: @map.getZoom()
    }

  render: =>
    {windowSize, isLoading} = @state.getValue()

    z '.z-map', {key: 'map', className: z.classKebab {isLoading}},
      z '.map', {key: 'map-container'}
      z '.loading', @$spinner
