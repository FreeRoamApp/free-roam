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

  getMeta: =>
    {
      canonical: "https://#{config.HOST}"
      title: @model.l.get 'meta.defaultTitle'
      description: @model.l.get 'meta.defaultDescription'
    }

  render: =>
    z '.p-home',
      @$spinner
