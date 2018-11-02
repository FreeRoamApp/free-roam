PlaceAttachments = require '../place_attachments'

module.exports = class CampgroundAttachments extends PlaceAttachments
  constructor: ({@model}) ->
    @placeAttachmentModel = @model.campgroundAttachment

    super
