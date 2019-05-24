z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
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
        @model.trip.getByType route.params.tripType

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$newCheckIn = new NewCheckIn {@model, @router, checkIn, trip}
    @$deleteIcon = new Icon()

    @state = z.state {checkIn}

  getMeta: =>
    {
      title: @model.l.get 'editCheckInPage.title'
    }

  render: =>
    {checkIn} = @state.getValue()

    z '.p-new-check-in',
      z @$appBar, {
        title: @model.l.get 'editCheckInPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
        $topRightButton:
          z @$deleteIcon,
            icon: 'delete'
            color: colors.$header500Icon
            hasRipple: true
            onclick: =>
              if confirm @model.l.get 'general.confirm'
                @model.checkIn.deleteByRow checkIn
                .then =>
                  @router.back()
      }
      @$newCheckIn
