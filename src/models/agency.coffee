module.exports = class Agency
  namespace: 'agencies'

  constructor: ({@auth}) -> null

  getAll: =>
    @auth.stream "#{@namespace}.getAll", {}

  getAgencyInfoFromLocation: (location) ->
    @auth.stream "#{@namespace}.getAgencyInfoFromLocation", {location}
