PlaceAttachments = require '../place_attachments'

module.exports = class AmenityAttachments extends PlaceAttachments
  constructor: ({@model}) ->
    @placeAttachmentModel = @model.amenityAttachment

    super
