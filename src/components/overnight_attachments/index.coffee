PlaceAttachments = require '../place_attachments'

module.exports = class OvernightAttachments extends PlaceAttachments
  constructor: ({@model}) ->
    @placeAttachmentModel = @model.overnightAttachment

    super
