z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
_map = require 'lodash/map'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
TripList = require '../../components/trip_list'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class ProfileTripsPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group}) ->
    @user = requests.switchMap ({route}) =>
      if route.params.username
        @model.user.getByUsername route.params.username
      else
        @model.user.getById route.params.id

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    trips = @user.switchMap (user) =>
      @model.trip.getAllByUserId user.id
    @$tripList = new TripList {
      @model, @router, trips
    }

    @state = z.state
      user: @user

  getMeta: =>
    @user.map (user) =>
      {
        title: @model.l.get 'profileTripsPage.title', {
          replacements:
            name: @model.user.getDisplayName user
        }
        description: @model.l.get 'profileTripsPage.description', {
          replacements:
            name: @model.user.getDisplayName user
        }
      }

  render: =>
    {user} = @state.getValue()

    console.log 'profile trips'

    z '.p-profile-trips',
      z @$appBar, {
        title: if user
          @model.l.get 'profileTripsPage.title', {
            replacements:
              name: @model.user.getDisplayName user
          }
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$header500Icon}
      }
      z @$tripList,
        emptyIcon: 'trip_mine_empty'
        emptyTitle: @model.l.get 'tripsMine.emptyTitle'
        emptyDescription: @model.l.get 'tripsMine.emptyDescription'
