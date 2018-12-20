z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
FlatButton = require '../../components/flat_button'
EditTrip = require '../../components/edit_trip'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditTripPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        @model.trip.getByType route.params.type

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$shareButton = new FlatButton()
    @$editTrip = new EditTrip {@model, @router, trip}

  getMeta: =>
    {
      title: @model.l.get 'editTripPage.title'
    }

  render: =>
    z '.p-edit-trip',
      z @$appBar, {
        title: @model.l.get 'editTripPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
        $topRightButton:
          z @$shareButton,
            text: @model.l.get 'general.share'
            onclick: =>
              @$editTrip.share()
      }
      @$editTrip
