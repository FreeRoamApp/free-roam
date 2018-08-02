z = require 'zorium'

Icon = require '../icon'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Partners
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @state = z.state {}

  render: =>
    {} = @state.getValue()

    z '.z-partners',
      z '.g-grid',
        'More info coming soon. The gist of it is for anyone that you refer to
        the site, your Amazon affiliate link is used 100% of the time.'
