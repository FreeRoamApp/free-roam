z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

PlacesMapContainer = require '../places_map_container'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Places
  constructor: ({@model, @router, @overlay$}) ->
    @$placesMapContainer = new PlacesMapContainer {
      @model, @router, @overlay$
      filters: @getFilters()
    }

    @state = z.state {}

  getFilters: =>
    [
      {
        field: 'roadDifficulty'
        type: 'maxInt'
        name: @model.l.get 'roadDifficulty.title'
        onclick: =>
          @filterDialogField.next 'roadDifficulty'
          @showFilterDialog()
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'crowds'
        type: 'maxInt'
        name: @model.l.get 'campground.crowds'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'cellSignal.att.signal'
        type: 'maxInt'
        name: @model.l.get 'campground.cellSignal'
        onclick: =>
          # modal, set carrier, min signal, 4g or 3g
          @setFilterByField 'cellSignal.att.signal', 6
          null
        valueSubject: new RxBehaviorSubject null
      }
      {
        field: 'location'
        type: 'geo'
        onclick: => null
        valueSubject: new RxBehaviorSubject null
      }
    ]

  render: =>
    {} = @state.getValue()

    z '.z-places',
      z @$placesMapContainer
