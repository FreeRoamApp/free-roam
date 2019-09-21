RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_uniqBy = require 'lodash/uniqBy'

module.exports = class PlaceBase
  namespace: 'places'

  constructor: ({@auth, @l, @offlineData}) -> null

  getPath: (place, router) ->
    router.get place.type, {slug: place.slug}

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  # socket.io compresses responses, so a 50kb response is more like 10kb
  search: ({query, tripId, tripRouteId, tripAltRouteSlug, sort, limit, includeId}) =>
    # this isn't cached, so make sure it's not sending same req twice
    # probably best to keep log...
    console.log 'searching', @namespace

    if navigator?.onLine is false
      console.log 'fetching offline places'
      RxObservable.of try
        JSON.parse localStorage["offlinePlaces.#{@namespace}"]
      catch
        {total: 0, places: []}
    else
      @auth.stream "#{@namespace}.search", {
        query, tripId, tripRouteId, tripAltRouteSlug, sort, limit, includeId
      }, {ignoreCache: true}
      .do if @offlineData?.isRecording then @_saveOffline else (-> null)

  # combine all loaded places and save for offline fetching
  _saveOffline: (places) =>
    existingPlaces = try
      JSON.parse localStorage["offlinePlaces.#{@namespace}"]
    catch
      null

    existingPlaces ?= {total: 0, places: []}

    placesArr = _uniqBy existingPlaces.places.concat(places.places), (place) ->
      place.id or JSON.stringify place.location

    localStorage["offlinePlaces.#{@namespace}"] = JSON.stringify(
      {total: places.total, places: placesArr}
    )

  # socket.io compresses responses, so a 50kb response is more like 10kb
  searchNearby: ({location, limit}) =>
    @auth.stream "#{@namespace}.searchNearby", {location, limit}

  upsert: (options, {invalidateAll} = {}) =>
    invalidateAll ?= true
    ga? 'send', 'event', 'ugc', 'place', @namespace, 1
    @auth.call "#{@namespace}.upsert", options, {invalidateAll}

  dedupe: (options) =>
    @auth.call "#{@namespace}.dedupe", options, {invalidateAll: true}

  deleteByRow: (row) =>
    @auth.call "#{@namespace}.deleteByRow", {row}, {invalidateAll: true}

  getNearestAmenitiesById: (id) =>
    @auth.stream "#{@namespace}.getNearestAmenitiesById", {id}

  getName: (place) ->
    if place?.name
      place?.name
    else if place?.address
      "#{place?.address?.locality}, #{place?.address?.administrativeArea}"
    else if place
      @l.get 'general.unknown'
    else
      '...'

  getLocation: (place) ->
    if place?.address
      "#{place?.address?.locality}, #{place?.address?.administrativeArea}"
    else if place
      @l.get 'general.unknown'
    else
      '...'

  getSheetInfo: (options) ->
    @auth.stream "#{@namespace}.getSheetInfo", options
