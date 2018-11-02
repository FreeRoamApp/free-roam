PlaceAttachments = require '../place_attachments'

module.exports = class ReviewlessCampgroundAttachments extends PlaceAttachments
  constructor: ({@model}) ->
    @placeAttachmentModel = @model.reviewlessCampgroundAttachment

    super
