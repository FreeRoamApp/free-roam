z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Map = require '../map'
Spinner = require '../spinner'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CampgroundNearby
  constructor: ({@model, @router, place}) ->

    places = place.map (place) ->
      if place then [place] else null

    @place = new RxBehaviorSubject null
    @placePosition = new RxBehaviorSubject null
    @mapSize = new RxBehaviorSubject null

    @$map = new Map {
      @model, @router, places
      @place, @placePosition, @mapSize
      setFilterByField: -> null # FIXME rm
    }

    @state = z.state
      place: place

  render: =>
    {place} = @state.getValue()

    z '.z-campground-nearby',
      z @$map
