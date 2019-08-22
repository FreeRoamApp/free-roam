module.exports = class PlaceBase
  namespace: 'places'

  constructor: ({@auth, @l}) -> null

  getPath: (place, router) ->
    router.get place.type, {slug: place.slug}

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  # socket.io compresses responses, so a 50kb response is more like 10kb
  search: ({query, tripId, tripRouteId, sort, limit, includeId}) =>
    @auth.stream "#{@namespace}.search", {
      query, tripId, tripRouteId, sort, limit, includeId
    }

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
