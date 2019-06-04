NewPlaceInitialInfo = require '../new_place_initial_info'

module.exports = class NewOvernightInitialInfo extends NewPlaceInitialInfo
  prettyType: 'Overnight'
  type: 'overnight'

  constructor: ({@model}) ->
    @subTypes = {
      restArea: @model.l.get 'overnight.restArea'
      other: @model.l.get 'overnight.other'
      truckStop: @model.l.get 'overnight.truckStop'
      casino: @model.l.get 'overnight.casino'
      crackerBarrel: @model.l.get 'overnight.crackerBarrel'
      walmart: @model.l.get 'overnight.walmart'
    }

    super
