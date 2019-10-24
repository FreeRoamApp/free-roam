z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/fromPromise'
require 'rxjs/add/observable/of'
_camelCase = require 'lodash/camelCase'
_startCase = require 'lodash/startCase'
_reduce = require 'lodash/reduce'
_filter = require 'lodash/filter'
_map = require 'lodash/map'
_defaults = require 'lodash/defaults'

CurrentLocation = require '../current_location'
FlatButton = require '../flat_button'
Icon = require '../icon'
PlaceList = require '../place_list'
Rating = require '../rating'
SecondaryButton = require '../secondary_button'
Spinner = require '../spinner'
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
    myLocation = @model.userLocation.getByMe().map (myLocation) ->
      myLocation or false

    @$currentLocation = new CurrentLocation {
      @model, @router, isPlacesOnly: true
    }

    hasLocationPermissionPromise = MapService.hasLocationPermission {@model}
    @hasLocationPermissionStreams = new RxReplaySubject 1
    @hasLocationPermissionStreams.next RxObservable.fromPromise(
      hasLocationPermissionPromise
    )
    @locationStreams = new RxReplaySubject 1
    @locationStreams.next RxObservable.fromPromise(
      hasLocationPermissionPromise.then (hasPermission) =>
        if hasPermission
          MapService.getLocation {@model}
    )
    location = @locationStreams.switch()

    @$nearbyPlaces = new PlaceList {
      @model, @router
      places: location.switchMap (location) =>
        @model.campground.searchNearby {location, limit: 3}
        .map (places) -> places?.places
    }
    @$addCampgroundButton = new SecondaryButton()
    @$updateLocationButton = new FlatButton()

    reviewValueStreams = new RxReplaySubject 1
    reviewValueStreams.next myLocation.switchMap (myLocation) =>
      unless myLocation?.place
        return RxObservable.of null
      place = myLocation.place
      @model.placeReview.getByUserIdAndParentId myLocation.userId, place.id

    ratingValueStreams = new RxReplaySubject 1
    ratingValueStreams.next reviewValueStreams.switch().map (review) ->
      review?.rating

    @$rating = new Rating {
      valueStreams: ratingValueStreams
      isInteractive: true
      onRate: (rating) =>
        {myLocation, review} = @state.getValue()
        place = myLocation.place
        @model["#{place.type}Review"].upsertRatingOnly {
          id: review?.id
          parentId: place.id
          rating: rating
        }
    }

    @$addReviewButton = new SecondaryButton()

    @$weatherIcon = new Icon()
    @$temperatureIcon = new Icon()
    @$rainIcon = new Icon()
    @$windIcon = new Icon()
    @$facilitiesAllIcon = new Icon()

    @$spinner = new Spinner()


    nearestAmenities = myLocation.switchMap (myLocation) =>
      unless myLocation?.place
        return RxObservable.of []
      @model[myLocation.place.type].getNearestAmenitiesById myLocation.place.id

    myLocationAndNearestAmenities = RxObservable.combineLatest(
      myLocation, nearestAmenities, (vals...) -> vals
    )

    @$nearbyFacilities = new PlaceList {
      @model, @router
      places: myLocationAndNearestAmenities
      .map ([myLocation, nearestAmenities]) =>
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
      review: reviewValueStreams.switch().map (review) ->
        review or false
      hasLocationPermission: @hasLocationPermissionStreams.switch()
      forecastDaily: myLocation.map (myLocation) ->
        place = myLocation?.place
        days = place?.forecast?.daily
        today = new Date()
        todayVal =
          today.getYear() * 366 + today.getMonth() * 31 + today.getDate()
        _filter _map days, (day) ->
          # TODO: use day.day instead
          date = new Date((day.time + 3600) * 1000)
          dateStr = "#{date.getMonth() + 1}/#{date.getDate()}"
          dateVal = date.getYear() * 366 + date.getMonth() * 31 + date.getDate()
          if dateVal < todayVal
            return
          _defaults {
            dow: date.getDay()
            date: dateStr
          }, day
    }

  render: =>
    {myLocation, forecastDaily, review,
      hasLocationPermission} = @state.getValue()

    todayForecast = forecastDaily?[0]
    icon = todayForecast?.icon?.replace 'night', 'day'
    weatherType = _startCase(icon).replace(/ /g, '')
    hasInfo = myLocation?.place?.type in ['campground', 'overnight']

    z '.z-dashboard',
      z '.g-grid',
        if myLocation and review?
          z '.current-location',
            z @$currentLocation
        if not myLocation? or not review?
          z @$spinner
        else if not myLocation or not hasInfo
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
                        cText: colors.$primaryMainText
                      onclick: =>
                        getLocationPromise = MapService.getLocation {@model}
                        @locationStreams.next RxObservable.fromPromise(
                          getLocationPromise
                        )
                        @hasLocationPermissionStreams.next(
                          RxObservable.fromPromise(
                            getLocationPromise.then (location) =>
                              MapService.hasLocationPermission {@model}
                          )
                        )
            if hasLocationPermission
              [
                z '.nearby',
                  z '.title', @model.l.get 'dashboard.emptyNearby'
                  z @$nearbyPlaces
                z '.add',
                  z @$addCampgroundButton,
                    text: @model.l.get 'dashboard.addCampground'
                    onclick: =>
                      @router.go 'newCampground'
              ]
        else
          [
            z '.rating',
              z @$rating, {size: '32px'}

              if review
                [
                  z '.text',
                    @model.l.get 'dashboard.leaveReview'
                  z '.action',
                    z @$addReviewButton,
                      text: @model.l.get 'placeInfo.addReview'
                      onclick: =>
                        @router.go 'editCampgroundReview', {
                          slug: myLocation.place.slug
                          reviewId: review.id
                        }, {ignoreHistory: true}
                ]
              else
                z '.text', @model.l.get 'dashboard.rate'

            z '.card.has-padding',
              z '.title', @model.l.get 'dashboard.weather'
              @router.link z 'a.weather', {
                className: z.classKebab {"is#{weatherType}": true}
                href: @router.get 'campground', {
                  slug: myLocation?.place?.slug
                }
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
              z @$nearbyFacilities
              @router.link z 'a.view-more', {
                href: @router.get 'campgroundWithTab', {
                  slug: myLocation?.place?.slug
                  tab: 'nearby'
                }
              },
                z '.text', @model.l.get 'dashboard.viewMore'
                z '.icon',
                  z @$facilitiesAllIcon,
                    icon: 'chevron-right'
                    color: colors.bgText70
                    isTouchTarget: false
          ]
