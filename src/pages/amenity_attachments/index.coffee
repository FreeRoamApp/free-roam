AmenityAttachments = require '../../components/amenity_attachments'
PlaceAttachmentsPage = require '../place_attachments'

module.exports = class AmenityAttachmentsPage extends PlaceAttachmentsPage
  PlaceAttachments: AmenityAttachments

  constructor: ({@model}) ->
    @placeModel = @model.amenity
    super
