z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

PlacesMapContainer = require '../places_map_container'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Places
  constructor: ({@model, @router, @overlay$}) ->
    @$placesMapContainer = new PlacesMapContainer {
      @model, @router, @overlay$
      dataTypes: [
        {
          dataType: 'campground'
          filters: @getCampgroundFilters()
          isChecked: true
        }
        {
          dataType: 'amenity'
          filters: @getAmenityFilters()
        }
      ]
      optionalLayers: [
        {
          name: @model.l.get 'placesMapContainer.layerBlm'
          color: colors.$mapLayerBlm
          layer: {
            id: 'us-blm'
            type: 'fill'
            source:
              type: 'vector'
              url: 'https://tileserver.freeroam.app/data/free-roam-us-blm.json'
            'source-layer': 'us_pad'
            layout: {}
            paint:
              'fill-color': colors.$mapLayerBlm
              'fill-opacity': 0.4
          }
          insertBeneathLabels: true
        }

        {
          name: @model.l.get 'placesMapContainer.layerUsfs'
          color: colors.$mapLayerUsfs
          layer: {
            id: 'us-usfs'
            type: 'fill'
            source:
              type: 'vector'
              url: 'https://tileserver.freeroam.app/data/free-roam-us-usfs.json'
            'source-layer': 'us_pad'
            layout: {}
            paint:
              'fill-color': colors.$mapLayerUsfs
              'fill-opacity': 0.4
          }
          insertBeneathLabels: true
        }
      ]
    }

    @state = z.state {}

  getAmenityFilters: =>
    MapService.getAmenityFilters {@model}

  getCampgroundFilters: =>
    [
      {
        field: 'roadDifficulty'
        type: 'maxInt'
        name: @model.l.get 'campground.roadDifficulty'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'crowds'
        type: 'maxIntSeasonal'
        name: @model.l.get 'campground.crowds'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'cellSignal'
        type: 'cellSignal'
        name: @model.l.get 'campground.cellSignal'
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'safety'
        type: 'minInt'
        name: @model.l.get 'campground.safety'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'noise'
        type: 'maxIntDayNight'
        name: @model.l.get 'campground.noise'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'fullness'
        type: 'maxIntSeasonal'
        name: @model.l.get 'campground.fullness'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'shade'
        type: 'maxInt'
        name: @model.l.get 'campground.shade'
        valueSubject: new RxBehaviorSubject null
      }
    ]

  render: =>
    {} = @state.getValue()

    z '.z-places',
      z @$placesMapContainer
