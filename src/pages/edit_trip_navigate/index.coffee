z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_find = require 'lodash/find'

AppBar = require '../../components/app_bar'
Icon = require '../../components/icon'
EditTripNavigate = require '../../components/edit_trip_navigate'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripNavigatePage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    trip = requests.switchMap ({route}) =>
      if route.params.id
        @model.trip.getById route.params.id
      else
        RxObservable.of null

    routeId = requests.map ({route}) =>
      route.params.routeId

    tripAndRouteId = RxObservable.combineLatest(
      trip, routeId, (vals...) -> vals
    )
    # TODO: don't grab all routes from server, just the one
    tripRoute = tripAndRouteId.map ([trip, routeId]) ->
      _find trip?.routes, {routeId}

    # mapBoundsStreams = new RxReplaySubject 1
    # mapBoundsStreams.next requests.switchMap ({route}) =>
    #   region = {
    #     country: route.params.country
    #     state: route.params.state
    #     city: route.params.city
    #   }
    #   unless route.params.country
    #     return RxObservable.of undefined
    #   @model.geocoder.getBoundingFromRegion region

    @$appBar = new AppBar {@model}
    @$closeIcon = new Icon()
    @$settingsIcon = new Icon()

    @$editTripNavigate = new EditTripNavigate {
      @model, @router, trip, tripRoute
    }

    @state = z.state
      trip: trip
      routeId: routeId

  getMeta: =>
    {
      title: @model.l.get 'editTripNavigatePage.stopTitle'
    }

  render: =>
    {trip, routeId} = @state.getValue()

    z '.p-edit-trip-navigate',
      z @$appBar, {
        title: @model.l.get 'editTripNavigatePage.title'
        isSecondary: true
        $topLeftButton: z @$closeIcon, {
          icon: 'close'
          color: colors.$secondary500Text
          onclick: =>
            @router.back()
        }
        $topRightButton: z @$settingsIcon, {
          icon: 'settings'
          color: colors.$secondary500Text
          onclick: =>
            @router.goOverlay 'editTripSettings', {
              id: trip?.id
            }
        }
      }
      @$editTripNavigate
      @$bottomBar
