z = require 'zorium'

if window?
  require './index.styl'

module.exports = class NewPlacePage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    @$newPlace = new @NewPlace {@model, @router}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newPlacePage.title', {
        replacements: {@prettyType}
      }
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-new-place', {
      style:
        height: "#{windowSize.height}px"
    },
      @$newPlace
