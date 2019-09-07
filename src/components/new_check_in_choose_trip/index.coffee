z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable

Icon = require '../icon'
TripList = require '../trip_list'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
Location (use place_search), photos

Is this a campground?

Want to help us help others? Add a little more info about this campground so
others can find it
###

module.exports = class NewCheckInInfo
  constructor: ({@model, @router, @checkIn, @fields, trip}) ->
    me = @model.user.getMe()

    @$tripList = new TripList {
      @model, @router, trips: @model.trip.getAll()
      selectedTripIdStreams: @fields.tripId.valueStreams
    }

    @state = z.state {
      selectedTripId: @fields.tripId.valueStreams.switch()
    }

  isCompleted: ->
    true

  render: =>
    {selectedTripId} = @state.getValue()

    z '.z-new-check-in-choose-trip',
      z '.g-grid',
        z @$tripList
