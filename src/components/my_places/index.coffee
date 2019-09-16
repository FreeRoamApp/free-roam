z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'
_filter = require 'lodash/filter'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'

PlaceList = require '../place_list'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class MyPlaces
  constructor: ({@model, @router}) ->
    checkIns = @model.checkIn.getAll {includeDetails: true}
    places = checkIns.map (checkIns) ->
      _filter _map checkIns, (checkIn) ->
        if checkIn?.place
          _defaults {
            checkInId: checkIn.id, name: checkIn.name or checkIn.place.name
          }, checkIn.place
    @$placeList = new PlaceList {
      @model, @router, places, action: 'openCheckIn'
    }

    @state = z.state {
      places: places
    }

  render: =>
    {places} = @state.getValue()

    z '.z-my-places',
      if places and _isEmpty places
        z '.empty',
          @model.l.get 'myPlaces.empty'
      else
        z @$placeList
