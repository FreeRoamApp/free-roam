Overnight = require '../../components/overnight'
PlacePage = require '../place'

module.exports = class OvernightPage extends PlacePage
  Place: Overnight

  constructor: ({@model}) ->
    @placeModel = @model.overnight
    @title = @model.l.get 'overnightPage.title'
    super
