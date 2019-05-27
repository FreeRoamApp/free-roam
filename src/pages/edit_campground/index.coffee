EditCampground = require '../../components/edit_campground'
EditPlacePage = require '../edit_place'

module.exports = class EditCampgroundPage extends EditPlacePage
  EditPlace: EditCampground

  constructor: ({@model}) ->
    @placeModel = @model.campground
    super
