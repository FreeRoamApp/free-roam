z = require 'zorium'

if window?
  require './index.styl'

module.exports = class NewPlacePage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    location = requests.map ({req}) =>
      req.query.location or ''

    @$newPlace = new @NewPlace {@model, @router, location}

  getMeta: =>
    {
      title: @model.l.get 'newPlacePage.title', {
        replacements: {@prettyType}
      }
    }

  render: =>
    z '.p-new-place',
      @$newPlace
