z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'

AttachmentsList = require '../attachments_list'
PlacesListCampground = require '../places_list_campground'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CheckIn
  constructor: ({@model, @router, checkIn}) ->
    @$placesListCampground = new PlacesListCampground {
      @model, @router, action: 'info'
      place: checkIn.map (checkIn) ->
        checkIn?.place
    }

    @$attachmentsList = new AttachmentsList {
      @model, @router
      attachments: checkIn.map (checkIn) -> checkIn.attachments
    }

    @state = z.state
      checkIn: checkIn

  render: =>
    {checkIn} = @state.getValue()

    z '.z-check-in',
      z '.g-grid',
        z '.place',
          z @$placesListCampground

        unless _isEmpty checkIn?.attachments
          [
            z '.title', @model.l.get 'general.photos'
            z '.photos',
              @$attachmentsList
          ]
