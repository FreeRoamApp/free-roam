NewPlaceInitialInfo = require '../new_place_initial_info'

module.exports = class NewOvernightInitialInfo extends NewPlaceInitialInfo
  prettyType: 'Overnight'
  type: 'overnight'

  constructor: ({@model}) ->
    @subTypes = {
      restArea: @model.l.get 'overnight.restArea'
      casino: @model.l.get 'overnight.casino'
      walmart: @model.l.get 'overnight.walmart'
    }

    super
