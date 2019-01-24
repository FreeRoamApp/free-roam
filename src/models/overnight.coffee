PlaceBase = require './place_base'

module.exports = class Overnight extends PlaceBase
  namespace: 'overnights'
  constructor: ({@auth}) -> null

  markIsAllowedById: (id, isAllowed) =>
    @auth.call "#{@namespace}.markIsAllowedById", {id, isAllowed}, {
      invalidateAll: true
    }

  getIsAllowedByMeAndId: (id) =>
    @auth.stream "#{@namespace}.getIsAllowedByMeAndId", {id}
