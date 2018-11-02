CampgroundAttachments = require '../../components/campground_attachments'
PlaceAttachmentsPage = require '../place_attachments'

module.exports = class CampgroundAttachmentsPage extends PlaceAttachmentsPage
  PlaceAttachments: CampgroundAttachments

  constructor: ({@model}) ->
    @placeModel = @model.campground
    super
