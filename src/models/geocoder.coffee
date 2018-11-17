module.exports = class Geocoder
  namespace: 'geocoder'

  constructor: ({@auth}) -> null

  autocomplete: ({query}) =>
    @auth.stream "#{@namespace}.autocomplete", {query}
