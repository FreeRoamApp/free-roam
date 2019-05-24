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
    @$viewButton = new FlatButton()
    @$shareButton = new FlatButton()
    @$editTrip = new EditTrip {@model, @router, trip}

    @state = z.state {trip}

  getMeta: =>
    {trip} = @state.getValue()

    {
      title: @model.l.get 'editTripPage.title', {
        replacements:
          name: trip?.name or ''
      }
    }

  render: =>
    {trip} = @state.getValue()

    z '.p-edit-trip',
      z @$appBar, {
        title: @model.l.get 'editTripPage.title', {
          replacements:
            name: trip?.name or ''
        }
        isPrimary: true
        $topLeftButton: z @$buttonBack, {color: colors.$primary500Text}
        $topRightButton:
          z '.p-edit-trip_top-right',
            z @$viewButton,
              text: @model.l.get 'general.view'
              colors:
                cText: colors.$primary500Text
              onclick: =>
                @router.go 'trip', {id: trip.id}
            z @$shareButton,
              text: @model.l.get 'general.share'
              colors:
                cText: colors.$primary500Text
              onclick: =>
                @$editTrip.share()
      }
      @$editTrip
