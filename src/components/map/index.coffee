z = require 'zorium'
_map = require 'lodash/map'

tile = require './tilejson'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Map
  type: 'Widget'

  constructor: ({@model, @router, item}) ->
    @state = z.state
      windowSize: @model.window.getSize()

  afterMount: (@$$el) =>
    @model.additionalScript.add 'css', 'https://cdnjs.cloudflare.com/ajax/libs/mapbox-gl/0.47.0/mapbox-gl.css'
    @model.additionalScript.add 'js', 'https://cdnjs.cloudflare.com/ajax/libs/mapbox-gl/0.47.0/mapbox-gl.js'

    setTimeout => # FIXME
      @map = new mapboxgl.Map {
        container: @$$el
        style: tile
        center: [-97.6, 30.5]
        zoom: 13
      }

      @map.on 'load', =>
        @map.addLayer {
          id: 'places'
          type: 'circle'
          source:
            type: 'geojson'
            data:
              type: 'FeatureCollection'
              features: []
          # could use symbol, but need spritesheet
          # https://www.mapbox.com/mapbox-gl-js/example/popup-on-click/
          # could also do the name of rv park to right of symbol
          paint:
            'circle-color': '#000000'
            'circle-radius': {
              # 1px @ zoom 8, 6px @ zoom 11, 40px @ zoom 16
              stops: [[8, 2], [11, 8], [16, 40]]
            }
        }

        @updateMarkers()

      @map.on 'moveend', @updateMarkers

      @map.addControl new mapboxgl.GeolocateControl {
        positionOptions:
          enableHighAccuracy: true
        trackUserLocation: true
      }

      @map.on 'click', 'places', (e) =>
        coordinates = e.features[0].geometry.coordinates.slice()
        description = e.features[0].properties.description
        # Ensure that if the map is zoomed out such that multiple
        # copies of the feature are visible, the popup appears
        # over the copy being pointed to.
        while Math.abs(e.lngLat.lng - (coordinates[0])) > 180
          coordinates[0] += if e.lngLat.lng > coordinates[0] then 360 else -360
        (new (mapboxgl.Popup)).setLngLat(coordinates).setHTML(description).addTo @map

      # Change the cursor to a pointer when the mouse is over the places layer.
      @map.on 'mouseenter', 'places', =>
        @map.getCanvas().style.cursor = 'pointer'

      # Change it back to a pointer when it leaves.
      @map.on 'mouseleave', 'places', =>
        @map.getCanvas().style.cursor = ''

    , 3000

  updateMarkers: =>
    @model.place.search {
      query:
        geo_bounding_box:
          location:
            top_left:
              lat: @map.getBounds()._ne.lat
              lon: @map.getBounds()._sw.lng
            bottom_right:
              lat: @map.getBounds()._sw.lat
              lon: @map.getBounds()._ne.lng
    }
    .take(1).subscribe (places) =>

      @map.getSource('places').setData {
        type: 'FeatureCollection'
        features: _map places, (place) ->
          {
            type: 'Feature'
            properties:
              description: place.name
            geometry:
              type: 'Point'
              coordinates: [
                place.location.lon
                place.location.lat
              ]
          }
        # could use symbol, but need spritesheet
        # https://www.mapbox.com/mapbox-gl-js/example/popup-on-click/
        # could also do the name of rv park to right of symbol
        paint:
          'circle-color': '#000000'
          'circle-radius': {
            # 1px @ zoom 8, 6px @ zoom 11, 40px @ zoom 16
            stops: [[8, 2], [11, 8], [16, 40]]
          }
      }

  render: =>
    {item, products, windowSize} = @state.getValue()

    z '.z-map', {key: 'map'}
