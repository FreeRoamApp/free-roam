z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/observable/of'

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
      route.params.type
    subType = requests.map ({route}) ->
      route.params.subType
    trip = requests.switchMap ({req}) =>
      if req.query.tripId
        @model.trip.getById req.query.tripId
      else
        RxObservable.of null
    @$places = new Places {@model, @router, isShell, type, subType, trip}

  getMeta: =>
    {
      title: @model.l.get 'general.places'
      description: @model.l.get 'meta.defaultDescription'
    }

  render: =>
    z '.p-places',
      # this is here so vdom doesn't change which div bototmBar is for
      # (other page components all have appBars)
      z '.app-bar-placeholder'
      @$places
      @$bottomBar
