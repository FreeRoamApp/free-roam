EditAmenity = require '../../components/new_amenity'
EditPlacePage = require '../edit_place'

module.exports = class EditAmenityPage extends EditPlacePage
  EditPlace: EditAmenity

  constructor: ({@model}) ->
    @placeModel = @model.amenity
    super
