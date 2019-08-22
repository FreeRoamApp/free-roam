z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_startCase = require 'lodash/startCase'
_camelCase = require 'lodash/camelCase'

Places = require '../../components/places'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacesPage
  # hideDrawer: true
  @hasBottomBar: true

  constructor: ({@model, @router, requests, serverData, group, @$bottomBar}) ->
    isShell = requests.map ({route}) ->
      route.params.type is 'shell'
    type = requests.map ({route}) ->
      _camelCase route.params.type
    .publishReplay(1).refCount()
    subType = requests.map ({route}) ->
      _camelCase route.params.subType
    .publishReplay(1).refCount()
    trip = requests.switchMap ({req}) =>
      if req.query.tripId
        @model.trip.getById req.query.tripId
      else
        RxObservable.of null
    .publishReplay(1).refCount()

    mapBoundsStreams = new RxReplaySubject 1
    mapBoundsStreams.next requests.switchMap ({route}) =>
      region = {
        country: route.params.country
        state: route.params.state
        city: route.params.city
      }
      unless route.params.country
        return RxObservable.of undefined
      @model.geocoder.getBoundingFromRegion region

    searchQuery = requests.map ({route}) ->
      if route.params.city is 'all'
        "#{route.params.state.toUpperCase()}"
      else if route.params.city
        "#{_startCase route.params.city}, #{route.params.state.toUpperCase()}"


    @$places = new Places {
      @model, @router, isShell, type, subType, trip, mapBoundsStreams
      searchQuery
    }

  getMeta: =>
    {
      title: @model.l.get 'meta.homePageTitle'
      description: @model.l.get 'meta.defaultDescription'
    }

  render: =>
    z '.p-places',
      # this is here so vdom doesn't change which div bototmBar is for
      # (other page components all have appBars)
      z '.app-bar-placeholder'
      @$places
      @$bottomBar
