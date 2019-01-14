z = require 'zorium'
RxReplaySubject = require('rxjs/ReplaySubject').ReplaySubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
_startCase = require 'lodash/startCase'

Base = require '../base'
CellBars = require '../cell_bars'
Icon = require '../icon'
InfoLevelTabs = require '../info_level_tabs'
InfoLevel = require '../info_level'
EmbeddedVideo = require '../embedded_video'
FormattedText = require '../formatted_text'
MasonryGrid = require '../masonry_grid'
Spinner = require '../spinner'
Rating = require '../rating'
UiCard = require '../ui_card'
Environment = require '../../services/environment'
MapService = require '../../services/map'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceInfo extends Base
  constructor: ({@model, @router, @place}) ->
    seasons =  [
      {key: 'spring', text: @model.l.get 'seasons.spring'}
      {key: 'summer', text: @model.l.get 'seasons.summer'}
      {key: 'fall', text: @model.l.get 'seasons.fall'}
      {key: 'winter', text: @model.l.get 'seasons.winter'}
    ]
    currentSeason = @model.time.getCurrentSeason()
    @$masonryGrid = new MasonryGrid {@model}
    @$crowdsInfoLevelTabs = new InfoLevelTabs {
      @model, @router, tabs: seasons
      selectedTab: currentSeason, key: 'crowds'
    }
    @$fullnessInfoLevelTabs = new InfoLevelTabs {
      @model, @router, tabs: seasons
      selectedTab: currentSeason, key: 'fullness'
    }
    @$noiseInfoLevelTabs = new InfoLevelTabs {
      @model, @router,
      tabs: [
        {key: 'day', text: @model.l.get 'general.day'}
        {key: 'night', text: @model.l.get 'general.night'}
      ]
      selectedTab: 'day'
      key: 'noise'
    }
    @$shadeInfoLevel = new InfoLevel {@model, @router, key: 'shade'}
    @$cleanlinessInfoLevel = new InfoLevel {@model, @router, key: 'cleanliness'}
    @$safetyInfoLevel = new InfoLevel {@model, @router, key: 'safety'}
    @$roadDifficultyInfoLevel = new InfoLevel {
      @model, @router, key: 'roadDifficulty'
    }
    @$rating = new Rating {
      value: @place.map (place) -> place?.rating
    }
    @$spinner = new Spinner()
    @$directionsIcon = new Icon()
    @$checkInIcon = new Icon()
    @$saveIcon = new Icon()
    @$respectCard = new UiCard()

    @$details = new FormattedText {
      text: @place.map (place) ->
        place?.details
      imageWidth: 'auto'
      isFullWidth: true
      embedVideos: false
      @model
      @router
      truncate:
        maxLength: 250
        height: 200
    }

    @checkInsStreams = new RxReplaySubject 1
    @resetValueStreams()
    checkIns = @checkInsStreams.switch()

    @state = z.state
      visitedSaving: false
      plannedSaving: false
      visitedCheckIn: checkIns.map (checkIns) ->
        _find(checkIns, {status: 'visited'}) or false
      plannedCheckIn: checkIns.map (checkIns) ->
        _find(checkIns, {status: 'planned'}) or false
      checkIns: checkIns
      amenities: @place.map (place) ->
        _map place?.amenities, (amenity) ->
          {
            amenity
            $icon: new Icon()
          }
      hasSeenRespectCard: @model.cookie.get 'hasSeenRespectCard'
      place: @place.map (place) =>
        {
          place
          $videos: _map place?.videos, (video) =>
            new EmbeddedVideo {@model, video, useParentWidth: true}
          cellCarriers: _map place?.cellSignal, (value, carrier) ->
            {
              carrier: carrier
              type: value.type
              $bars: new CellBars {value: value.signal, includeNoSignal: true}
            }
        }

  resetValueStreams: =>
    checkInsAndPlace = RxObservable.combineLatest(
      @model.checkIn.getAll()
      @place
      (vals...) -> vals
    )

    @checkInsStreams.next checkInsAndPlace.map ([checkIns, place]) ->
      _filter checkIns, {sourceId: place?.id}

  afterMount: =>
    super
    # FIXME: figure out why i can't use take(1) here...
    # returns null for some. probably has to do with the unloading we do in
    # pages/base
    @disposable = @place.subscribe (place) =>
      if place?.attachmentsPreview?.count
        @fadeInWhenLoaded @getCoverUrl(place)

  beforeUnmount: =>
    super
    @disposable?.unsubscribe()
    @state.set isSaving: false
    @resetValueStreams()

  getCoverUrl: (place) =>
    @model.image.getSrcByPrefix(
      place.attachmentsPreview.first.prefix, 'large'
    )

  checkIn: (status) =>
    {place, checkIns} = @state.getValue()
    place = place.place

    ga? 'send', 'event', 'placeInfo', 'checkIn', status

    @state.set "#{status}Saving": true
    checkIn = _find checkIns, {status}
    if checkIn
      @model.checkIn.deleteByRow {
        id: checkIn.id
      }
      .then (checkIn) =>
        @state.set "#{status}Saving": false
        @checkInsStreams.next RxObservable.of _filter checkIns, (checkIn) ->
          checkIn.status isnt status
    else
      @model.checkIn.upsert {
        name: place.name
        sourceType: place.type
        sourceId: place.id
        status: status
      }
      .then (checkIn) =>
        @state.set "#{status}Saving": false
        @checkInsStreams.next RxObservable.of checkIns.concat checkIn
        @model.statusBar.open {
          text: @model.l.get "placeInfo.#{status}Saved"
          type: 'snack'
          timeMs: 5000
          action:
            text: @model.l.get 'placeInfo.viewTrip'
            onclick: =>
              @router.go 'editTripByType', {
                type: if status is 'visited' then 'past' else 'future'
              }
              @model.statusBar.close()

        }

  render: =>
    {place, visitedCheckIn, plannedCheckIn, checkIns, visitedSaving,
      plannedSaving, amenities, hasSeenRespectCard} = @state.getValue()

    {place, $videos, cellCarriers} = place or {}

    # spinner as a class so the dom structure stays the same between loads
    isLoading = not place?.slug
    z '.z-place-info', {
      className: z.classKebab {isLoading, @isImageLoaded}
    },
      if place?.attachmentsPreview?.count
        src = @getCoverUrl place
        z '.cover', {
          style:
            backgroundImage: "url(#{src})"
        },
          @router.link z 'a.see-more', {
            href: @router.get "#{place?.type}Attachments", {
              slug: place?.slug
            }
          },
            @model.l.get 'placeInfo.seeAll', {
              replacements: {count: place.attachmentsPreview.count}
            }
      z '.g-grid',
        z '.top-info',
          z '.left',
            z '.location',
              if place?.address?.locality
                "#{place.address.locality}, #{place.address.administrativeArea}"
            z '.rating',
              z @$rating, {size: '20px'}
          z '.right',
            z '.price',
              if place?.prices?.all?.mode is 0
                @model.l.get 'general.free'
              else if place?.prices?.all?.mode
                [
                  @model.l.get 'placeInfo.approx'
                  " $#{place?.prices?.all?.mode} / #{@model.l.get 'general.day'}"
                ]
              else
                "$ #{@model.l.get 'general.unknown'}"


        z '.action-box',
          z '.actions',
            z '.action', {
              onclick: =>
                MapService.getDirections place, {@model}
            },
              z '.icon',
                z @$directionsIcon,
                  icon: 'directions'
                  isTouchTarget: false
                  color: colors.$bgText54
              z '.text', @model.l.get 'general.directions'
            if place?.type isnt 'amenity'
              [
                z '.divider'
                z '.action', {
                  onclick: =>
                    @checkIn 'visited'
                },
                  z '.icon',
                    z @$checkInIcon,
                      icon: 'location'
                      isTouchTarget: false
                      color: if visitedCheckIn \
                             then colors.$primary500
                             else colors.$bgText54
                  z '.text',
                    if visitedSaving then @model.l.get 'general.saving'
                    else if visitedCheckIn then @model.l.get 'placeInfo.checkedIn'
                    else @model.l.get 'placeInfo.checkIn'
              ]
            z '.divider'
            z '.action', {
              onclick: => @checkIn 'planned'
            },
              z '.icon',
                z @$saveIcon,
                  icon: 'star'
                  isTouchTarget: false
                  color: if plannedCheckIn \
                         then colors.$primary500
                         else colors.$bgText54
              z '.text',
                if plannedSaving then @model.l.get 'general.saving'
                else if plannedCheckIn then @model.l.get 'general.saved'
                else @model.l.get 'general.save'

        z '.contact',
          z '.coordinates',
            z 'span.title', "#{@model.l.get 'newPlaceInitialInfo.coordinates'}: "
            "#{place?.location?.lat}, #{place?.location?.lon}"

          if place?.contact?.phone
            matches = place.contact?.phone?.number.match(
              /^(\d{3})(\d{3})(\d{4})$/
            )
            phone = if matches
              "(#{matches[1]}) #{matches[2]}-#{matches[3]}"
            z '.phone',
              z 'span.title', @model.l.get 'place.phone'
              phone
          if place?.contact?.website
            z '.website',
              z 'span.title', @model.l.get 'place.website'
              z 'a', {
                href: place.contact?.website
                onclick: (e) =>
                  e?.preventDefault()
                  @model.portal.call 'browser.openWindow', {
                    url: place.contact?.website
                    target: '_system'
                  }
              }, place.contact?.website

        if place?.type is 'campground' and not hasSeenRespectCard
          z '.card',
            z @$respectCard, {
              $title: @model.l.get 'preservationPage.title'
              $content: @model.l.get 'placeInfo.respectCard'
              cancel:
                text: @model.l.get 'general.readMore'
                onclick: =>
                  @router.go 'preservation'
              submit:
                text: @model.l.get 'general.gotIt'
                onclick: =>
                  @state.set hasSeenRespectCard: true
                  @model.cookie.set 'hasSeenRespectCard', '1'
            }

        if place?.type is 'amenity'
          _map amenities, ({amenity, $icon}) ->
            console.log amenity, $icon
            z '.amenity',
              z '.icon',
                z $icon,
                  icon: amenity
                  isTouchTarget: false
                  size: '16px'
                  color: colors["$amenity#{amenity}"]

              z '.name', amenity

        if place?.drivingInstructions
          z '.driving-instructions',
            z '.title', @model.l.get 'campground.drivingInstructions'
            place?.drivingInstructions

        if place?.details
          z '.details',
            z '.title', @model.l.get 'place.details'
            @$details

        z '.masonry',
          z @$masonryGrid,
            columnCounts:
              mobile: 1
              desktop: 2
              tablet: 2
            $elements: _filter [
              unless _isEmpty cellCarriers
                z '.section',
                  z '.title', @model.l.get 'campground.cellSignal'
                  z '.carriers',
                    _map cellCarriers, ({$bars, carrier, type}) =>
                      z '.carrier',
                        z '.name', @model.l.get "carriers.#{carrier}"
                        z '.bars',
                          z $bars, widthPx: 40
                        z '.type', type


              # z '.section',

                # TODO: icons for pets (paw), padSurface (road), entryType (car-brake-parking), allowedTypes, maxDays?,
                # hasFreshWater (water), hasSewage (poop), has30Amp (power-plug), has50Amp, maxLength (rule), restrooms (toilet)?


              if place?.crowds
                z '.section',
                  z '.title', @model.l.get 'campground.crowds'
                  z @$crowdsInfoLevelTabs, {
                    value: place?.crowds
                  }
              if place?.fullness
                z '.section',
                  z '.title', @model.l.get 'campground.fullness'
                  z @$fullnessInfoLevelTabs, {
                    value: place?.fullness
                  }
              if place?.noise
                z '.section',
                  z '.title', @model.l.get 'campground.noise'
                  z @$noiseInfoLevelTabs, {
                    value: place?.noise
                  }
              if place?.shade
                z '.section',
                  z '.title', @model.l.get 'campground.shade'
                  z @$shadeInfoLevel, {
                    value: place?.shade
                  }
              if place?.cleanliness
                z '.section',
                  z '.title', @model.l.get 'campground.cleanliness'
                  z @$cleanlinessInfoLevel, {
                    value: place?.cleanliness
                    isReversed: true # 5 is bad 1 is good
                  }
              if place?.safety
                z '.section',
                  z '.title', @model.l.get 'campground.safety'
                  z @$safetyInfoLevel, {
                    value: place?.safety
                    isReversed: true # 5 is bad 1 is good
                  }
              if place?.roadDifficulty
                z '.section',
                  z '.title', @model.l.get 'campground.roadDifficulty'
                  z @$roadDifficultyInfoLevel, {
                    value: place?.roadDifficulty
                  }

              if place?.weather
                z '.section',
                  z '.title', @model.l.get 'placeInfo.averageWeather'
                  z 'img.graph', {
                    src:
                      "#{config.USER_CDN_URL}/weather/#{place?.type}_#{place?.id}.svg?12"
                  }

              unless _isEmpty $videos
                z '.section',
                  z '.title', @model.l.get 'general.videos'
                  z '.videos'
                    _map $videos, ($video) ->
                      z $video
            ]

      z '.spinner', z @$spinner
