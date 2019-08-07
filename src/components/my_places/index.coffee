z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'

PlaceList = require '../place_list'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class MyPlaces
  constructor: ({@model, @router}) ->
    places = @model.checkIn.getAll {includeDetails: true}
    @$placeList = new PlaceList {
      @model, @router, places, action: 'info'
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
