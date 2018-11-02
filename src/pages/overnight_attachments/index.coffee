OvernightAttachments = require '../../components/overnight_attachments'
PlaceAttachmentsPage = require '../place_attachments'

module.exports = class OvernightAttachmentsPage extends PlaceAttachmentsPage
  PlaceAttachments: OvernightAttachments

  constructor: ({@model}) ->
    @placeModel = @model.overnight
    super
