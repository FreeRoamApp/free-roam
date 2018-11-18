z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'
_filter = require 'lodash/filter'

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
Environment = require '../../services/environment'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CampgroundInfo extends Base
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
    @$safetyInfoLevel = new InfoLevel {@model, @router, key: 'safety'}
    @$roadDifficultyInfoLevel = new InfoLevel {
      @model, @router, key: 'roadDifficulty'
    }
    @$rating = new Rating {
      value: @place.map (place) -> place?.rating
    }
    @$spinner = new Spinner()

    @$details = new FormattedText {
      text: @place.map (place) ->
        place?.details
      imageWidth: 'auto'
      isFullWidth: true
      embedVideos: false
      @model
      @router
    }

    @state = z.state
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

  getCoverUrl: (place) =>
    @model.image.getSrcByPrefix(
      place.attachmentsPreview.first.prefix, 'large'
    )

  render: =>
    {place} = @state.getValue()

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
            @model.l.get 'campgroundInfo.seeAll', {
              replacements: {count: place.attachmentsPreview.count}
            }
      z '.g-grid',
        z '.location',
          if place?.address?.locality
            "#{place.address.locality}, #{place.address.administrativeArea}"
          ' ('
          z 'span.get-directions', {
            onclick: =>
              target = '_system'
              baseUrl = 'https://google.com/maps/dir/?api=1'
              destination = place?.location?.lat + ',' + place?.location?.lon
              onLocation = ({coords}) =>
                origin = coords?.latitude + ',' + coords?.longitude
                url = "#{baseUrl}&origin=#{origin}&destination=#{destination}"
                @model.portal.call 'browser.openWindow', {url, target}
              onError = =>
                url = "#{baseUrl}&origin=My+Location&destination=#{destination}"
                @model.portal.call 'browser.openWindow', {url, target}
              if Environment.isNativeApp 'freeroam'
                console.log 'good'
                navigator.geolocation.getCurrentPosition onLocation, onError
              else
                console.log 'err'
                # just use the "my location" version, to avoid popup blocker
                onError()

          }, @model.l.get 'general.directions'
          ')'

        z '.rating',
          z @$rating, {size: '20px'}

        if place?.contact
          z '.contact',
            if place.contact.phone
              matches = place.contact?.phone?.number.match(
                /^(\d{3})(\d{3})(\d{4})$/
              )
              phone = if matches
                "(#{matches[1]}) #{matches[2]}-#{matches[3]}"
              z '.phone',
                z 'span.title', @model.l.get 'place.phone'
                phone
            if place.contact.website
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
                  z '.title', @model.l.get 'campgroundInfo.averageWeather'
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
