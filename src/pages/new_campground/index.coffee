z = require 'zorium'

NewCampground = require '../../components/new_campground'

if window?
  require './index.styl'

module.exports = class NewCampgroundPage
  hideDrawer: true

  constructor: ({@model, requests, @router, overlay$, serverData}) ->
    @$newCampground = new NewCampground {@model, @router, overlay$}

    @state = z.state
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      title: @model.l.get 'newCampgroundPage.title'
    }

  render: =>
    {windowSize} = @state.getValue()

    z '.p-new-campground', {
      style:
        height: "#{windowSize.height}px"
    },
      @$newCampground
