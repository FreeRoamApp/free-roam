z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
_map = require 'lodash/map'

tile = require './tilejson'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Map
  type: 'Widget'

  constructor: (options) ->
    {@model, @router, @places, @setFilterByField,
      @place, @placePosition, @mapSize} = options

    @$spinner = new Spinner()

    @state = z.state
      isLoading: true
      windowSize: @model.window.getSize()

  getClosestPixelRatio: ->
    if window.devicePixelRatio > 1.5 then 2 else 1

  afterMount: (@$$el) =>
    pixelRatio = @getClosestPixelRatio()

    @state.set isLoading: true

    # TODO update after this is resolved
    # https://github.com/mapbox/mapbox-gl-js/issues/6722
    @model.additionalScript.add 'css', 'https://cdnjs.cloudflare.com/ajax/libs/mapbox-gl/0.49.0/mapbox-gl.css'
    @model.additionalScript.add 'js', 'https://cdnjs.cloudflare.com/ajax/libs/mapbox-gl/0.49.0/mapbox-gl.js'
    .then =>
      @map = new mapboxgl.Map {
        container: @$$el
        style: tile
        center: [-109.283071, 34.718803]
        zoom: 4
      }

      @map.on 'load', =>
        markerSrc = "#{config.CDN_URL}/maps/markers/default@#{pixelRatio}x.png"
        @map.loadImage markerSrc, (err, image) =>
          @map.addImage 'marker', image, {pixelRatio: pixelRatio}
          @resizeSubscription = @model.window.getSize().subscribe =>
            setImmediate =>
              @map.resize()
              @mapSize.next {
                width: @$$el.offsetWidth, height: @$$el.offsetHeight
              }
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
              # there is a bug where markers don't show if zoomed in on another area then zoom out.
              # not sure how to fix
              'icon-image': 'marker' # uses spritesheet defined in tilejson.coffee
              'icon-allow-overlap': true
              # 'icon-ignore-placement': true
              'icon-size': 1
              'icon-anchor': 'bottom'

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
              'text-font': ['Klokantech Noto Sans Regular'] # must exist in tilejson

            paint:
              'text-translate': [12, -4]
              'text-halo-color': 'rgba(255, 255, 255, 1)'
              'text-halo-width': 2
              #  # 3px @ zoom 8, 10px @ zoom 11, 50px @ zoom 16
              #  stops: [[8, 3], [11, 10], [16, 50]]
          }

          @updateMapBounds()
          @subscribeToPlaces()
          @state.set isLoading: false

      @map.on 'move', @onMapMove
      @map.on 'moveend', @updateMapBounds

      @map.addControl new mapboxgl.GeolocateControl {
        positionOptions:
          enableHighAccuracy: true
        trackUserLocation: true
      }

      @map.on 'click', 'places', (e) =>
        coordinates = e.features[0].geometry.coordinates.slice()
        name = e.features[0].properties.name
        slug = e.features[0].properties.slug
        type = e.features[0].properties.type
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
          position: position
          location: coordinates
        }
        # (new mapboxgl.Popup({offset: 25})).setLngLat(coordinates).setHTML(description).addTo @map

      # Change the cursor to a pointer when the mouse is over the places layer.
      @map.on 'mouseenter', 'places', =>
        @map.getCanvas().style.cursor = 'pointer'

      # Change it back to a pointer when it leaves.
      @map.on 'mouseleave', 'places', =>
        @map.getCanvas().style.cursor = ''

    , 3000

  beforeUnmount: =>
    @disposable?.unsubscribe()
    @resizeSubscription?.unsubscribe()

  subscribeToPlaces: =>
    @disposable = @places.subscribe (places) =>
      @map.getSource('places').setData {
        type: 'FeatureCollection'
        features: _map places, (place) ->
          {
            type: 'Feature'
            properties:
              name: place.name
              slug: place.slug
              type: place.type
            geometry:
              type: 'Point'
              coordinates: [
                place.location.lon
                place.location.lat
              ]
          }
      }

  # update tooltip pos
  onMapMove: =>
    if place = @place.getValue()
      @placePosition.next @map.project place.location

  updateMapBounds: =>
    @setFilterByField 'location', @map.getBounds()

  render: =>
    {windowSize, isLoading} = @state.getValue()

    z '.z-map', {key: 'map', className: z.classKebab {isLoading}},
      z '.map', {key: 'map-container'}
      z '.loading', @$spinner
