z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

PlaceMap = require '../../components/place_map'
config = require '../../config'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class PlaceMapScreenshot
  isPlain: true

  constructor: ({@model, @router, requests, serverData}) ->
    @place = requests.switchMap ({route}) =>
      console.log 'screenshot', route.params
      if route.params.slug
        @model.placeBase.getByTypeAndSlug route.params.type, route.params.slug
      else
        RxObservable.of null

    @$placeMap = new PlaceMap {
      @model, @router, @place, prepScreenshot: true
    }

  getMeta: -> null

  render: =>
    console.log 'rend'
    z '.p-place-map-screenshot',
      @$placeMap
