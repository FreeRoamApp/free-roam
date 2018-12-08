z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'

PlacesList = require '../places_list'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class MyPlaces
  constructor: ({@model, @router}) ->
    places = @model.savedPlace.getAll {includeDetails: true}
    @$placesList = new PlacesList {
      @model, @router
      places: places
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
        z @$placesList
