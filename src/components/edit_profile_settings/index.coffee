z = require 'zorium'

Icon = require '../icon'
Toggle = require '../toggle'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditProfileSettings
  constructor: ({@model, @router, @fields}) ->
    me = @model.user.getMe()

    @$autoCheckInToggle = new Toggle
      valueStreams: @fields.username.valueStreams
      error: @fields.username.errorSubject

    @state = z.state
      me: me

  render: =>
    {me} = @state.getValue()

    z '.z-edit-profile-settings',
      z '.g-grid',
        z '.section',
          z '.input',
            z @$autoCheckInToggle
