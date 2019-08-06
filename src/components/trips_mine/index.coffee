z = require 'zorium'

SecondaryButton = require '../secondary_button'
TripList = require '../trip_list'

if window?
  require './index.styl'

module.exports = class TripsMine
  constructor: ({@model, @router}) ->
    trips = @model.trip.getAll()

    @$createCustom = new SecondaryButton()
    @$tripList = new TripList {@model, @router, trips}

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-trips-mine',
      z '.create-button',
        z @$createCustom,
          text: @model.l.get 'tripsMine.createCustom'
          onclick: =>
            @router.go 'newTrip'
      z @$tripList
