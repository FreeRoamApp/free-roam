config = require '../config'

PlaceBase = require './place_base'

module.exports = class Campground extends PlaceBase
  namespace: 'campgrounds'

  getAmenityBoundsById: (id) =>
    @auth.stream "#{@namespace}.getAmenityBoundsById", {id}
