z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

ActionBar = require '../action_bar'
Map = require '../map'

if window?
  require './index.styl'

module.exports = class CoordinatePicker
  constructor: ({@model, @router, @coordinates, @overlay$}) ->
    @$actionBar = new ActionBar {@model}

    @places = new RxBehaviorSubject []
    @mapCenter = new RxBehaviorSubject null

    @$map = new Map {
      @model, @router, @places, center: @mapCenter, initialZoom: 4
      onclick: (e) =>
        lat = Math.round(1000 * e.lngLat.lat) / 1000
        lon = Math.round(1000 * e.lngLat.lng) / 1000
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
    }

  render: =>
    {coordinates} = @state.getValue()

    z '.z-coordinate-picker',
      z @$actionBar, {
        isSaving: false
        title: coordinates or @model.l.get 'coordinatePicker.title'
        cancel:
          text: @model.l.get 'general.discard'
          onclick: =>
            @overlay$.next null
        save:
          text: @model.l.get 'general.done'
          onclick: (e) =>
            @coordinates.next coordinates
            @overlay$.next null
      }
      z '.map',
        z @$map
