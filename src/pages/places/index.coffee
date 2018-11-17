z = require 'zorium'

Places = require '../../components/places'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesPage
  # hideDrawer: true
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    @$places = new Places {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'general.places'
      description: @model.l.get 'meta.defaultDescription'
    }

  render: =>
    z '.p-places',
      @$places
      @$bottomBar
