z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_find = require 'lodash/find'

ActionBar = require '../action_bar'
Map = require '../map'
MapService = require '../../services/map'

if window?
  require './index.styl'

module.exports = class CoordinatePicker
  constructor: (options) ->
    {@model, @router, @coordinates, @coordinatesSteams,
      center, initialZoom} = options

    @$actionBar = new ActionBar {@model}

    @places = new RxBehaviorSubject []
    @mapCenter = new RxBehaviorSubject center
    initialZoom ?= 4

    @$map = new Map {
      @model, @router, @places, center: @mapCenter, initialZoom
      onclick: (e) =>
        lat = Math.round(10000 * e.lngLat.lat) / 10000
        lon = Math.round(10000 * e.lngLat.lng) / 10000
        coordinates = "#{lat}, #{lon}"
        @state.set {coordinates}
        @places.next [{
          name: coordinates
          slug: ''
          type: ''
          location:
            lon: e.lngLat.lng
            lat: e.lngLat.lat
        }]
    }

    @state = z.state {
      coordinates: ''
      isSatelliteVisible: false
    }

  toggleSatellite: =>
    {isSatelliteVisible} = @state.getValue()

    layers = MapService.getOptionalLayers {@model}
    {layer, source, sourceId, insertBeneathLabels} = _find layers, (layer) ->
      layer.layer.id is 'satellite'

    @state.set isSatelliteVisible: not isSatelliteVisible
    @$map.toggleLayer layer, {
      insertBeneathLabels
      source: source
      sourceId: sourceId
    }

  render: =>
    {coordinates, isSatelliteVisible} = @state.getValue()

    z '.z-coordinate-picker',
      z @$actionBar, {
        isSaving: false
        title: coordinates or @model.l.get 'coordinatePicker.title'
        cancel:
          text: @model.l.get 'general.discard'
          onclick: =>
            @model.overlay.close()
        save:
          text: @model.l.get 'general.done'
          onclick: (e) =>
            @coordinates?.next coordinates
            @coordinatesSteams?.next RxObservable.of coordinates
            @model.overlay.close()
      }
      z '.map',
        z '.toggle-satellite', {
          onclick: @toggleSatellite
        },
          if isSatelliteVisible
            @model.l.get 'coordinatePicker.hideSatellite'
          else
            @model.l.get 'coordinatePicker.showSatellite'
        z @$map
