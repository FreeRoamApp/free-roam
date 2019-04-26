PlaceBase = require './place_base'

module.exports = class UserLocation extends PlaceBase
  namespace: 'userLocations'

  getByMe: =>
    @auth.stream "#{@namespace}.getByMe", {}
