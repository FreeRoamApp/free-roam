z = require 'zorium'

Toggle = require '../toggle'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripRouteInfoElevation
  constructor: (options) ->
    {@model, avoidHighwaysStreams, useTruckRouteStreams,
      isEditingRoute} = options

    @$avoidHighwaysToggle = new Toggle
      isSelectedStreams: avoidHighwaysStreams

    @$useTruckRouteToggle = new Toggle
      isSelectedStreams: useTruckRouteStreams

    @$isEditingRouteToggle = new Toggle
      isSelected: isEditingRoute

    # @state = z.state {}

  render: =>
    # {} = @state.getValue()

    z '.z-edit-trip-route-info-settings',
      z '.field',
        z '.title', @model.l.get 'editTripRouteInfoSettings.isEditingRoute'
        z '.content',
          z '.description',
            @model.l.get 'editTripRouteInfoSettings.isEditingRouteDescription'
          z '.input',
            z @$isEditingRouteToggle

      z '.field',
        z '.title', @model.l.get 'editTripSettings.avoidHighways'
        z '.content',
          z '.description',
            @model.l.get 'editTripRouteInfoSettings.avoidHighwaysDescription'
          z '.input',
            z @$avoidHighwaysToggle

      z '.field',
        z '.title', @model.l.get 'editTripSettings.useTruckRoute'
        z '.content',
          z '.description',
            @model.l.get 'editTripRouteInfoSettings.useTruckRouteDescription'
          z '.input',
            z @$useTruckRouteToggle
