RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
module.exports = class Geocoder
  namespace: 'geocoder'

  constructor: ({@auth}) -> null

  autocomplete: ({query, includeGeocode}) =>
    @auth.stream "#{@namespace}.autocomplete", {query, includeGeocode}

  getBoundingFromRegion: ({country, state, city}) ->
    @auth.stream "#{@namespace}.getBoundingFromRegion", {
      country, state, city
    }

  getBoundingFromLocation: (location) ->
    @auth.call "#{@namespace}.getBoundingFromLocation", {location}

  getFeaturesFromLocation: (location, {file} = {}) ->
    @auth.stream "#{@namespace}.getFeaturesFromLocation", {location, file}
