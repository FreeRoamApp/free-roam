z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Backpack
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-backpack',
      z '.g-grid',
        'Coming soon. The backpack will be a place to save items for later'
