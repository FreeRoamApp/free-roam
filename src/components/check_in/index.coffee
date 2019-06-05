z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'

AttachmentsList = require '../attachments_list'
PlacesListCampground = require '../places_list_campground'
DateService = require '../../services/date'
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
        z '.info',
          z '.name', @model.checkIn.getName checkIn
          if checkIn?.startTime
            z '.date',
              DateService.format new Date(checkIn.startTime), 'MMM D'
        z '.place',
          z '.title', @model.l.get "placeType.#{checkIn?.place?.type}"
          z @$placesListCampground

        unless _isEmpty checkIn?.attachments
          [
            z '.title', @model.l.get 'general.photos'
            z '.photos',
              @$attachmentsList
          ]
