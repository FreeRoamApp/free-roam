z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonMenu = require '../../components/button_menu'
FlatButton = require '../../components/flat_button'
EditTrip = require '../../components/edit_trip'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditTripPage
  constructor: ({@model, @router, requests, serverData, group}) ->
    trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        @model.trip.getByType route.params.type

    @$appBar = new AppBar {@model}
    @$buttonMenu = new ButtonMenu {@model, @router}
    @$viewButton = new FlatButton()
    @$shareButton = new FlatButton()
    @$editTrip = new EditTrip {@model, @router, trip}

    @state = z.state {trip}

  getMeta: =>
    {
      title: @model.l.get 'editTripPage.title'
    }

  render: =>
    {trip} = @state.getValue()

    z '.p-edit-trip',
      z @$appBar, {
        title: @model.l.get 'editTripPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonMenu, {color: colors.$header500Icon}
        $topRightButton:
          z '.p-edit-trip_top-right',
            z @$viewButton,
              text: @model.l.get 'general.view'
              onclick: =>
                @router.go 'trip', {id: trip.id}
            z @$shareButton,
              text: @model.l.get 'general.share'
              onclick: =>
                @$editTrip.share()
      }
      @$editTrip
