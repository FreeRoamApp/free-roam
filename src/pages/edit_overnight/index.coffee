EditOvernight = require '../../components/new_overnight'
EditPlacePage = require '../edit_place'

module.exports = class EditOvernightPage extends EditPlacePage
  EditPlace: EditOvernight

  constructor: ({@model}) ->
    @placeModel = @model.overnight
    super
