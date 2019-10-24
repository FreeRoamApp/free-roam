z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
NewTrip = require '../../components/new_trip'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class NewTripPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$newTrip = new NewTrip {@model, @router}

  getMeta: =>
    {
      title: @model.l.get 'newTripPage.title', {
        replacements:
          prettyType: 'Trip'
      }
    }

  render: =>
    z '.p-new-trip',
      z @$appBar, {
        title: @model.l.get 'newTripPage.title'
        isPrimary: true
        $topLeftButton: z @$buttonBack, {color: colors.$primaryMainText}
      }
      @$newTrip
