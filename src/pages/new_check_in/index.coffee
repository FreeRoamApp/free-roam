z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

NewCheckIn = require '../../components/new_check_in'
Icon = require '../../components/icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class NewCheckInPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    checkIn = requests.switchMap ({route}) =>
      if route.params.id
        @model.checkIn.getById route.params.id
      else
        RxObservable.of null

    trip = requests.switchMap ({route}) =>
      if route.params.tripId
        @model.trip.getById route.params.tripId
      else
        RxObservable.of null

    @$newCheckIn = new NewCheckIn {@model, @router, checkIn, trip}

    @state = z.state {checkIn}

  getMeta: =>
    {
      title: @model.l.get 'editCheckInPage.title'
    }

  render: =>
    {checkIn} = @state.getValue()

    z '.p-new-check-in',
      @$newCheckIn
