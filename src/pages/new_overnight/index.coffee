NewOvernight = require '../../components/new_overnight'
NewPlacePage = require '../new_place'

module.exports = class NewOvernightPage extends NewPlacePage
  NewPlace: NewOvernight
  prettyType: 'Overnight'
