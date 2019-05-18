module.exports = class PlaceBase
  constructor: ({@auth, @l}) -> null

  getPath: (place, router) ->
    router.get place.type, {slug: place.slug}

  getBySlug: (slug) =>
    @auth.stream "#{@namespace}.getBySlug", {slug}

  # socket.io compresses responses, so a 50kb response is more like 10kb
  search: ({query, tripId, sort, limit}) =>
    @auth.stream "#{@namespace}.search", {query, tripId, sort, limit}

  # socket.io compresses responses, so a 50kb response is more like 10kb
  searchNearby: ({location, limit}) =>
    @auth.stream "#{@namespace}.searchNearby", {location, limit}

  upsert: (options, {invalidateAll} = {}) =>
    invalidateAll ?= true
    @auth.call "#{@namespace}.upsert", options, {invalidateAll}

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
