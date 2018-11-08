z = require 'zorium'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class StatusBar
  constructor: ({@model}) ->
    @state = z.state
      data: @model.statusBar.getData()

  render: =>
    {data} = @state.getValue()

    z '.z-status-bar', {
      onclick: ->
        data?.onclick?()
    },
      data?.text
