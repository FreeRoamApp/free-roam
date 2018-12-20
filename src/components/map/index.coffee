z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'
_flatten = require 'lodash/flatten'
_forEach = require 'lodash/forEach'

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
      @place, @placePosition, @mapSize, @initialZoom, @zoom, @initialCenter,
      @initialBounds, @route, @initialLayers, @center, @defaultOpacity,
      @onclick, @preserveDrawingBuffer, @onContentReady, @hideLabels} = options

    @place ?= new RxBehaviorSubject null
    @defaultOpacity ?= 1

    @initialZoom ?= 4
    @initialCenter ?= [-105.894, 40.048]

    @layers = []
    @$spinner = new Spinner()

    @state = z.state
      isLoading: true
      windowSize: @model.window.getSize()

  getClosestPixelRatio: ->
    if window.devicePixelRatio > 1.5 then 2 else 1

  getFirstSymbolId: =>
    layers = @map.getStyle().layers
    # Find the index of the first symbol layer in the map style
    firstSymbolId = undefined
    i = 0
    while i < layers.length
      if layers[i].type is 'symbol'
        firstSymbolId = layers[i].id
        break
      i += 1
    return firstSymbolId

  addLayer: (layer, {source, sourceId, insertBeneathLabels} = {}) =>
    if @layers.indexOf(layer.id) is -1
      @layers.push layer.id
      layerId = if insertBeneathLabels then @getFirstSymbolId() else undefined
      try
        @map.addSource sourceId or layer.id, source
      catch err
        console.log 'source exists', err
      @map.addLayer layer, layerId

  removeLayerById: (id) =>
    index = @layers.indexOf(id)
    if index isnt -1
      @layers.splice index, 1
    layer = @map.getLayer id
    source = layer.source
    @map.removeLayer id
    # @map.removeSource source

  toggleLayer: (layer, options) =>
    if @layers.indexOf(layer.id) is -1
      @addLayer layer, options
    else
      @removeLayerById layer.id

  getBlob: =>
    new Promise (resolve) =>
      @map.getCanvas().toBlob resolve

  afterMount: ($$el) =>
    @state.set isLoading: true

    $$mapEl = $$el.querySelector('.map')

    fitBounds = null

    @model.additionalScript.add 'css', "#{config.SCRIPTS_CDN_URL}/mapbox-gl-0.51.0.css"
    @model.additionalScript.add 'js', "#{config.SCRIPTS_CDN_URL}/mapbox-gl-0.51.0.js"
    .then =>
      console.log '%cNEW MAPBOX MAP', 'color: red'
      mapboxgl.accessToken = config.MAPBOX_ACCESS_TOKEN
      @map = new mapboxgl.Map {
        container: $$mapEl
        style: tile
        center: @initialCenter
        zoom: @initialZoom
        bounds: @initialBounds
        preserveDrawingBuffer: @preserveDrawingBuffer
      }

      if @mapBoundsStreams
        @subscribeToMapBounds()

      @map.on 'load', =>
        console.log 'map loaded'
        if @hideLabels
          @_hideLabels()
        @resizeSubscription = @model.window.getSize().subscribe =>
          setTimeout =>
            @map?.resize()
            @mapSize?.next {
              width: $$mapEl.offsetWidth, height: $$mapEl.offsetHeight
            }
          , 0
        @map.addLayer {
          id: 'places'
          type: 'symbol'
          source:
            type: 'geojson'
            data:
              type: 'FeatureCollection'
              features: []
          # need spritesheet for symbols.
          # eg. https://www.mapbox.com/mapbox-gl-js/example/popup-on-click/
          # keep in mind these don't use svgs...
          # could also do the name of rv park to right of symbol

          layout:
            'icon-image': '{icon}' # uses spritesheet defined in tilejson.coffee
            'icon-allow-overlap': true
            # 'icon-ignore-placement': true
            'icon-size': 1
            'icon-anchor': 'bottom'


            # having text causes icons to occasionally show then fade out and
            # back. i think??? because of the opacity stops hack.
            # alternative is creating two layers using same source, with minzoom
            # and maxzoom, but i think that's less performant.
            # text-opacity isn't a good solution as it has same fading issue,
            # and the transparent text is still clickable
            # maybe this fixes:
            # https://github.com/mapbox/mapbox-gl-js/issues/6692
            'text-field': '{name}'
            'text-optional': true
            # 'text-ignore-placement': true
            'text-anchor': 'bottom-left'
            'text-size':
              stops: [
                [0, 0]
                [6, 0]
                [6.001, 12]
              ]
            'text-font': ['Open Sans Regular'] # must exist in tilejson

          paint:
            # 'icon-opacity': ['case', ['to-boolean', ['get', 'iconOpacity']], ['get', 'iconOpacity'], 0.1]
            'icon-opacity': ['get', 'iconOpacity']
            'text-opacity': ['get', 'iconOpacity']
            'text-translate': [12, -4]
            'text-halo-color': 'rgba(255, 255, 255, 1)'
            'text-halo-width': 2
            #  # 3px @ zoom 8, 10px @ zoom 11, 50px @ zoom 16
            #  stops: [[8, 3], [11, 10], [16, 50]]
        }
        if @route
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
          routeSubscription = @subscribeToRoute()

        @addInitialLayers()

        @updateMapLocation()
        placeSubscription = @subscribeToPlaces()
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
      else
        @map.on 'click', =>
          @place.next null

        console.log 'listen ctx'
        @map.on 'contextmenu', (e) =>
          e.originalEvent.preventDefault()

          @placePosition.next e.point

          latRounded = Math.round(e.lngLat.lat * 1000) / 1000
          lonRounded = Math.round(e.lngLat.lng * 1000) / 1000

          @place.next {
            name: "#{latRounded}, #{lonRounded}"
            type: 'coordinate'
            position: e.point
            location: [e.lngLat.lng, e.lngLat.lat]
          }

        @map.on 'click', 'places', (e) =>
          coordinates = e.features[0].geometry.coordinates.slice()
          name = e.features[0].properties.name
          description = e.features[0].properties.description
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
            slug: slug
            type: type
            name: name
            description: description
            rating: rating
            thumbnailPrefix: thumbnailPrefix
            position: position
            location: coordinates
          }

      # Change the cursor to a pointer when the mouse is over the places layer.
      @map.on 'mouseenter', 'places', =>
        @map.getCanvas().style.cursor = 'pointer'

      # Change it back to a pointer when it leaves.
      @map.on 'mouseleave', 'places', =>
        @map.getCanvas().style.cursor = ''

  beforeUnmount: =>
    console.log 'rm subscription'
    @disposable?.unsubscribe()
    @routeDisposable?.unsubscribe()
    @mapBoundsStreamsDisposable?.unsubscribe()
    @centerDisposable?.unsubscribe()
    @zoomDisposable?.unsubscribe()
    @resizeSubscription?.unsubscribe()
    @map?.remove()
    @map = null

  _hideLabels: =>
    _forEach @map.style.stylesheet.layers, (layer) =>
      if layer.type is 'symbol'
        @map.removeLayer layer.id

  addInitialLayers: =>
    _map @initialLayers, (initialLayer) =>
      {layer, insertBeneathLabels, source, sourceId} = initialLayer

      @addLayer layer, {
        insertBeneathLabels
        source: source
        sourceId: sourceId
      }

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

  subscribeToPlaces: =>
    console.log 'create subscription'
    @disposable = @places.subscribe (places) =>
      @map.getSource('places')?.setData {
        type: 'FeatureCollection'
        features: _map places, (place) =>
          {
            type: 'Feature'
            properties:
              name: place.name
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
    if place = @place.getValue()
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
