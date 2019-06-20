RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
module.exports = class Geocoder
  namespace: 'geocoder'

  constructor: ({@auth}) -> null

  autocomplete: ({query}) =>
    @auth.stream "#{@namespace}.autocomplete", {query}

  getBoundingFromRegion: ({country, state, city}) ->
    @auth.stream "#{@namespace}.getBoundingFromRegion", {
      country, state, city
    }

  getBoundingFromLocation: (location) ->
    @auth.call "#{@namespace}.getBoundingFromLocation", {location}

  getElevationFromLocation: (location) ->
    @auth.stream "#{@namespace}.getElevationFromLocation", {location}

  getFeaturesFromLocation: (location) ->
    @auth.stream "#{@namespace}.getFeaturesFromLocation", {location}
