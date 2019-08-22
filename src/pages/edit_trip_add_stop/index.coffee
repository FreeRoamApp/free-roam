z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/observable/of'
_find = require 'lodash/find'

AppBar = require '../../components/app_bar'
Icon = require '../../components/icon'
Places = require '../../components/places'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class EditTripAddStopPage
  hideDrawer: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    trip = requests.switchMap ({route}) =>
      console.log route.params.id
      if route.params.id
        @model.trip.getById route.params.id
      else
        RxObservable.of null

    routeId = requests.map ({route}) =>
      console.log 'rid', route.params.routeId
      route.params.routeId

    tripAndRouteId = RxObservable.combineLatest(
      trip, routeId, (vals...) -> vals
    )
    tripRoute = tripAndRouteId.map ([trip, routeId]) ->
      console.log 'rooooooooooo'
      console.log trip?.routes, routeId
      _find trip.routes, {id: routeId}

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

    @$places = new Places {
      @model, @router, trip, tripRoute
    }

  getMeta: =>
    {
      title: @model.l.get 'editTripAddStopPage.title'
    }

  render: =>
    z '.p-edit-trip-add-stop',
      z @$appBar, {
        title: @model.l.get 'editTripAddStopPage.title'
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
            null
        }
      }
      @$places
      @$bottomBar
