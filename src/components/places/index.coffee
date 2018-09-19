z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

PlacesMapContainer = require '../places_map_container'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
location should be its own filter.

pass in [
  {type: ['amenity', 'campground', 'cellTower'], filters}

]
###

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
    }

    @state = z.state {}

  getAmenityFilters: =>
    []

  getCampgroundFilters: =>
    currentSeason = @model.time.getCurrentSeason()

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
