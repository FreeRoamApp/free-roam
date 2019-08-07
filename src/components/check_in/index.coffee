z = require 'zorium'
_isEmpty = require 'lodash/isEmpty'

AttachmentsList = require '../attachments_list'
FormattedText = require '../formatted_text'
PlaceListItem = require '../place_list_item'
PrimaryButton = require '../primary_button'
DateService = require '../../services/date'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CheckIn
  constructor: ({@model, @router, checkIn}) ->
    @$placeListItem = new PlaceListItem {
      @model, @router
      place: checkIn.map (checkIn) ->
        checkIn?.place
    }

    @$infoButton = new PrimaryButton()
    @$directionsButton = new PrimaryButton()

    @$attachmentsList = new AttachmentsList {
      @model, @router
      attachments: checkIn.map (checkIn) -> checkIn.attachments
    }

    @$notes = new FormattedText {
      text: checkIn.map (checkIn) -> checkIn?.notes
      imageWidth: 'auto'
      isFullWidth: true
      @model
      @router
    }

    @state = z.state
      checkIn: checkIn

  render: =>
    {checkIn} = @state.getValue()

    placePath = if checkIn?.place
      @model.placeBase.getPath checkIn.place, @router

    z '.z-check-in',
      z '.g-grid',
        z '.place',
          z '.title', @model.l.get "placeType.#{checkIn?.place?.type}"
          z @$placeListItem

        z '.actions',
          if placePath
            z '.action',
              z @$infoButton,
                text: @model.l.get 'general.info'
                isOutline: true
                onclick: =>
                  @router.goPath placePath

          z '.action',
            z @$directionsButton,
              text: @model.l.get 'general.directions'
              onclick: =>
                MapService.getDirections(
                  checkIn.place, {@model}
                )

        if checkIn?.notes
          [
            z '.title', @model.l.get 'general.notes'
            z '.notes', @$notes
          ]

        unless _isEmpty checkIn?.attachments
          [
            z '.title', @model.l.get 'general.photos'
            z '.photos',
              @$attachmentsList
          ]
