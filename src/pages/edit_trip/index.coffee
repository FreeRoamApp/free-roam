z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
NewTrip = require '../../components/new_trip'
Icon = require '../../components/icon'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class EditTripPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        RxObservable.of null

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$newTrip = new NewTrip {@model, @router, trip}
    @$deleteIcon = new Icon()

    @state = z.state {trip}

  getMeta: =>
    {
      title: @model.l.get 'newTripPage.title'
    }

  render: =>
    {trip} = @state.getValue()

    z '.p-edit-trip',
      z @$appBar, {
        title: @model.l.get 'editTripPage.title'
        style: 'primary'
        $topLeftButton: z @$buttonBack
        $topRightButton:
          if trip?.id and trip.type is 'custom'
            z @$deleteIcon,
              icon: 'delete'
              color: colors.$header500Icon
              hasRipple: true
              onclick: =>
                if confirm @model.l.get 'general.confirm'
                  @model.trip.deleteByRow trip
                  .then =>
                    @router.go 'trips'
      }
      @$newTrip
