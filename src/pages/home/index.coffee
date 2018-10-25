z = require 'zorium'

Spinner = require '../../components/spinner'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class HomePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @$spinner = new Spinner()

    @state = z.state
      me: @model.user.getMe()
      windowSize: @model.window.getSize()

  getMeta: =>
    {
      canonical: "https://#{config.HOST}"
      title: @model.l.get 'meta.defaultTitle'
      description: @model.l.get 'meta.defaultDescription'
    }

  render: =>
    {me, windowSize} = @state.getValue()

    z '.p-home', {
      style:
        height: "#{windowSize.height}px"
    },
      @$spinner
