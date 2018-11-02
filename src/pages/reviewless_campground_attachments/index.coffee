ReviewlessCampgroundAttachments = require '../../components/reviewless_campground_attachments'
PlaceAttachmentsPage = require '../place_attachments'

module.exports = class ReviewlessCampgroundAttachmentsPage extends PlaceAttachmentsPage
  PlaceAttachments: ReviewlessCampgroundAttachments

  constructor: ({@model}) ->
    @placeModel = @model.reviewlessCampground
    super
