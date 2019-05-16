z = require 'zorium'

CoordinatePicker = require '../coordinate_picker'
Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CurrentLocation
  constructor: ({@model, @router}) ->
    @$locationIcon = new Icon()
    @$changeIcon = new Icon()

    @state = z.state {
      myLocation: @model.userLocation.getByMe()
    }

  openCoordinatePicker: =>
    @model.overlay.open new CoordinatePicker {
      @model, @router
      pickButtonText: @model.l.get 'placeInfo.checkIn'
      onPick: (place) =>
        console.log 'place', place
        (if not place.id
          @model.coordinate.upsert {
            name: place.name
            location: place.location
          }, {invalidateAll: false}
        else
          Promise.resolve place)
        .then ({id}) =>
          @model.checkIn.upsert {
            name: place.name
            sourceType: place.type or 'coordinate'
            sourceId: place.id or id
            setUserLocation: true
          }
    }

  render: =>
    {myLocation} = @state.getValue()

    console.log myLocation

    z '.z-current-location',
      z '.icon',
        z @$locationIcon,
          icon: 'marker-outline'
          color: colors.$bgText87
          isTouchTarget: false
      z '.location',
        if myLocation
          [
            z '.name', @model.placeBase.getName myLocation.place
            z '.date', 'test'
          ]
        else
          z '.name', @model.l.get 'usersNearby.emptyLocation'
      z '.change',
        z @$changeIcon,
          icon: 'edit-outline'
          color: colors.$bgText87
          onclick: @openCoordinatePicker
