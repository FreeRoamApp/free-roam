PlaceBase = require './place_base'

module.exports = class Event extends PlaceBase
  namespace: 'events'

  getAll: =>
    @auth.stream "#{@namespace}.getAll"
