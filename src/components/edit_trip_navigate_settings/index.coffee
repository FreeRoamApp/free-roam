z = require 'zorium'

Toggle = require '../toggle'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripNavigateElevation
  constructor: (options) ->
    {@model, avoidHighwaysStreams, useTruckRouteStreams,
      isEditable} = options

    @$avoidHighwaysToggle = new Toggle
      isSelectedStreams: avoidHighwaysStreams

    @$useTruckRouteToggle = new Toggle
      isSelectedStreams: useTruckRouteStreams

    @$isEditableToggle = new Toggle
      isSelected: isEditable

    @state = z.state {

    }

  render: =>
    {} = @state.getValue()

    z '.z-edit-trip-navigate-settings',
      z '.field',
        z '.title', @model.l.get 'editTripNavigateSettings.isEditable'
        z '.content',
          z '.description',
            @model.l.get 'editTripNavigateSettings.isEditableDescription'
          z '.input',
            z @$isEditableToggle

      z '.field',
        z '.title', @model.l.get 'editTripSettings.avoidHighways'
        z '.content',
          z '.description',
            @model.l.get 'editTripNavigateSettings.avoidHighwaysDescription'
          z '.input',
            z @$avoidHighwaysToggle

      z '.field',
        z '.title', @model.l.get 'editTripSettings.useTruckRoute'
        z '.content',
          z '.description',
            @model.l.get 'editTripNavigateSettings.useTruckRouteDescription'
          z '.input',
            z @$useTruckRouteToggle
