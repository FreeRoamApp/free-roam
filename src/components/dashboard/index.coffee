z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/fromPromise'
_camelCase = require 'lodash/camelCase'
_startCase = require 'lodash/startCase'
_reduce = require 'lodash/reduce'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'

CurrentLocation = require '../current_location'
Icon = require '../icon'
PlacesList = require '../places_list'
Rating = require '../rating'
SecondaryButton = require '../secondary_button'
FlatButton = require '../flat_button'
FormatService = require '../../services/format'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

###
FIXME FIXME: current location can't be updated if location sharing is off. it should be updatable still.... just not searchable
###

module.exports = class Dashboard
  constructor: ({@model, @router}) ->
    me = @model.user.getMe()

    @$currentLocation = new CurrentLocation {@model, @router}

    hasLocationPermissionPromise = MapService.hasLocationPermission()
    @hasLocationPermissionStreams = new RxReplaySubject 1
    @hasLocationPermissionStreams.next RxObservable.fromPromise(
      hasLocationPermissionPromise
    )
    @locationStreams = new RxReplaySubject 1
    @locationStreams.next RxObservable.fromPromise(
      hasLocationPermissionPromise.then (hasPermission) ->
        if hasPermission
          MapService.getLocation()
    )
    location = @locationStreams.switch()

    @$nearbyPlaces = new PlacesList {
      @model, @router
      places: location.switchMap (location) =>
        @model.campground.searchNearby {location, limit: 3}
        .map (places) -> places?.places
    }
    @$addCampgroundButton = new SecondaryButton()
    @$updateLocationButton = new FlatButton()

    @$rating = new Rating {
      # FIXME: get current review / rating and set this...
      isInteractive: true
      onRate: (rating) =>
        console.log 'rate', rating
        {myLocation} = @state.getValue()
        place = myLocation.place
        @model["#{place.type}Review"].upsertRatingOnly {
          parentId: place.id
          rating: rating
        }
    }

    @$weatherIcon = new Icon()
    @$temperatureIcon = new Icon()
    @$rainIcon = new Icon()
    @$windIcon = new Icon()


    myLocation = @model.userLocation.getByMe()
    nearestAmenities = myLocation.switchMap (myLocation) =>
      unless myLocation?.place
        return RxObservable.of []
      @model[myLocation.place.type].getNearestAmenitiesById myLocation.place.id

    myLocationAndNearestAmenities = RxObservable.combineLatest(
      myLocation, nearestAmenities, (vals...) -> vals
    )

    @$nearbyFacilities = new PlacesList {
      @model, @router
      places: myLocationAndNearestAmenities
      .map ([myLocation, nearestAmenities]) =>
        console.log 'near', nearestAmenities
        knownDistances = _reduce myLocation?.place?.distanceTo, (obj, distanceTo) ->
          {id, time, distance} = distanceTo
          obj[id] = {time, distance}
          obj
        , {}

        places = nearestAmenities or []
        places = _map places, (nearbyPlace) ->
          if knownDistance = knownDistances[nearbyPlace.id]
            _defaults {
              distance: knownDistance
            }, nearbyPlace
          else
            nearbyPlace
    }


    @state = z.state {
      myLocation
      hasLocationPermission: @hasLocationPermissionStreams.switch()
    }

  render: =>
    {myLocation, hasLocationPermission} = @state.getValue()

    todayForecast = myLocation?.place?.forecast?.daily?[0]
    icon = todayForecast?.icon
    weatherType = _startCase(icon).replace(/ /g, '')

    console.log hasLocationPermission

    z '.z-dashboard',
      z '.g-grid',
        if not myLocation
          z '.empty',
            z '.info-card',
              z '.title', @model.l.get 'dashboard.emptyLocationTitle'
              z '.description',
                @model.l.get 'dashboard.emptyLocationDescription'
              unless hasLocationPermission
                z '.actions',
                  z '.action',
                    z @$updateLocationButton,
                      text: @model.l.get 'dashboard.updateLocation'
                      icon: 'marker-outline'
                      isFullWidth: false
                      colors:
                        cText: colors.$primary500Text
                      onclick: =>
                        getLocationPromise = MapService.getLocation()
                        @locationStreams.next RxObservable.fromPromise(
                          getLocationPromise
                        )
                        @hasLocationPermissionStreams.next(
                          RxObservable.fromPromise(
                            getLocationPromise.then (location) ->
                              MapService.hasLocationPermission()
                          )
                        )
            if hasLocationPermission
              [
                z '.nearby',
                  z '.title', @model.l.get 'dashboard.emptyNearby'
                  @$nearbyPlaces
                z '.add',
                  z @$addCampgroundButton,
                    text: @model.l.get 'dashboard.addCampground'
                    onclick: =>
                      @router.go 'newCampground'
              ]
        else
          [
            z '.current-location',
              z @$currentLocation

              z '.rating',
                z @$rating, {size: '32px'}
                z '.text', @model.l.get 'dashboard.rate'

            z '.card',
              z '.title', @model.l.get 'dashboard.weather'
              z '.weather', {
                className: z.classKebab {"is#{weatherType}": true}
              },
                z '.icon',
                  z @$weatherIcon,
                    icon: "weather-#{icon}"
                    isTouchTarget: false
                    size: '72px'
                    color: colors.$white
                z '.info',
                  z '.date', @model.l.get 'general.today'
                  z '.text', @model.l.get "weather.#{_camelCase weatherType}"
                  z '.high-low',
                    z '.icon',
                      z @$temperatureIcon,
                        icon: 'thermometer'
                        size: '20px'
                        isTouchTarget: false
                        color: colors.$white
                    z '.high', Math.round(todayForecast?.temperatureHigh) + '°'
                    z '.divider', '|'
                    z '.low', Math.round(todayForecast?.temperatureLow) + '°F'
                  z '.rain',
                    z '.icon',
                      z @$rainIcon,
                        icon: 'water'
                        size: '20px'
                        isTouchTarget: false
                        color: colors.$white
                    z '.percent', FormatService.percentage todayForecast?.precipProbability
                    z '.divider', '|'
                    z '.amount', "#{todayForecast?.precipTotal}\""
                  z '.wind',
                    z '.icon',
                      z @$windIcon,
                        icon: 'weather-wind'
                        size: '20px'
                        isTouchTarget: false
                        color: colors.$white
                    z '.info',
                      z '.speed',
                        z 'span.type',
                          @model.l.get 'placeInfoWeather.windSpeed'
                          ': '
                        Math.round todayForecast?.windSpeed
                        z 'span.caption', 'MPH'
                      z '.gust',
                        z 'span.type',
                          @model.l.get 'placeInfoWeather.windGust'
                          ': '
                        Math.round todayForecast?.windGust
                        z 'span.caption', 'MPH'

            z '.card',
              z '.title', @model.l.get 'dashboard.nearby'
              z @$nearbyFacilities, {isPlain: true}
          ]
