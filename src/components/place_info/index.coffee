z = require 'zorium'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'
_filter = require 'lodash/filter'
_kebabCase = require 'lodash/kebabCase'

Base = require '../base'
ActionBox = require '../place_info_action_box'
CellBars = require '../cell_bars'
Contact = require '../place_info_contact'
Icon = require '../icon'
InfoLevel = require '../info_level'
EmbeddedVideo = require '../embedded_video'
MasonryGrid = require '../masonry_grid'
FormattedText = require '../formatted_text'
Rating = require '../rating'
Spinner = require '../spinner'
UiCard = require '../ui_card'
WalmartInfoCard = require '../walmart_info_card'
Weather = require '../place_info_weather'
Environment = require '../../services/environment'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/pin-s-fuel+dbad49(-121.783189,43.215686)/-121.783189,43.215686,17,0.00,0.00/320x320@2x?access_token=pk.eyJ1IjoiYXVzdGluaGFsbG9jayIsImEiOiJjam50azRkM3EwdW11M3Bwa3JhZmpwd25yIn0.s77eqcPCfwJ3NnPX7UvMpg

module.exports = class PlaceInfo extends Base
  constructor: ({@model, @router, @place, @trip}) ->
    @seasons =  [
      {key: 'spring', text: @model.l.get 'seasons.spring'}
      {key: 'summer', text: @model.l.get 'seasons.summer'}
      {key: 'fall', text: @model.l.get 'seasons.fall'}
      {key: 'winter', text: @model.l.get 'seasons.winter'}
    ]
    @$warningIcon = new Icon()
    @$actionBox = new ActionBox {@model, @router, @place, @trip}
    @$contact = new Contact {@model, @router, @place}
    @$placeInfoWeather = new Weather {@model, @router, @place}
    @$masonryGrid = new MasonryGrid {@model}
    @$crowdsInfoLevel = new InfoLevel {
      @model, @router, key: 'crowds'
    }
    @$fullnessInfoLevel = new InfoLevel {
      @model, @router, key: 'fullness'
    }
    @$noiseInfoLevel = new InfoLevel {
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
    @$respectCard = new UiCard()
    @$walmartInfoCard = new WalmartInfoCard {@model, @place}

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

    @state = z.state
      season: @model.time.getCurrentSeason()
      windowSize: @model.window.getSize()
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
          features: _filter _map place?.features, (val, feature) ->
            if val
              {
                feature: feature
                icon: config.FEATURES_ICONS[feature] or _kebabCase feature
                $icon: new Icon()
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
      place.attachmentsPreview.first.prefix, {size: 'large'}
    )

  render: =>
    {place, amenities, hasSeenRespectCard,
      season, windowSize} = @state.getValue()

    {place, $videos, cellCarriers, features} = place or {}

    cellBarsWidthPx = Math.min(
      (windowSize.width - 32 - 48) / 4
      100
    )

    console.log 'ppp', place

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
      else
        z '.no-cover' # we want a div here so vdom doesn't move everything else
      if place?.forecast?.fireWeather
        z '.warning',
          z '.g-grid',
            z '.icon',
              z @$warningIcon,
                icon: 'warning'
                isTouchTarget: false
                color: colors.$red500Text
            z '.text', @model.l.get 'placeInfo.fireWarning'
      z '.g-grid',
        if place?.type is 'campground'
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

        z '.name',
          place?.name

        # z '.location',
        #   if place?.address?.locality
        #     "#{place.address.locality}, #{place.address.administrativeArea}"
        z '.rating',
          z @$rating, {size: '20px', color: colors.$secondaryMain}
          z '.rating-text',
            if place?.rating
              "#{place?.rating.toFixed(1)}"
            z 'span.rating-count',
              ' ('
              @model.l.get 'place.reviewCount', {
                replacements:
                  count: place?.ratingCount or 0
              }
              ')'

        z '.action-box',
          z @$actionBox

        if place?.type is 'campground' and not hasSeenRespectCard
          z '.card',
            z @$respectCard, {
              $title: @model.l.get 'preservationPage.title'
              $content: @model.l.get 'placeInfo.respectCard'
              cancel:
                text: @model.l.get 'general.readMore'
                onclick: =>
                  @router.go 'roamWithCare'
              submit:
                text: @model.l.get 'general.gotIt'
                onclick: =>
                  @state.set hasSeenRespectCard: true
                  @model.cookie.set 'hasSeenRespectCard', '1'
            }

        if place?.subType in ['walmart', 'crackerBarrel', 'cabelas']
          totalCount = (place.isAllowedCount or 0) +
                          (place.isNotAllowedCount or 0)
          z '.is-overnight-allowed', {
            className: z.classKebab {
              isRed: totalCount and place.isAllowedScore < 0.4
              isYellow: not totalCount or (
                place.isAllowedScore >= 0.4 and place.isAllowedScore <= 0.7
              )
              isGreen: place.isAllowedScore > 0.7
            }
          },
            if totalCount
              @model.l.get 'placeInfo.isOvernightAllowed', {
                replacements:
                  yesCount: place.isAllowedCount or 0
                  totalCount: totalCount
              }
            else
              @model.l.get 'placeInfo.isOvernightAllowedIDK'


        if place?.subType in ['walmart', 'crackerBarrel', 'cabelas']
          z '.card',
            z @$walmartInfoCard

        z '.masonry',
          z @$masonryGrid,
            columnCounts:
              mobile: 1
              desktop: 2
              tablet: 2
            $elements: _filter [
              if place?.details
                z '.section',
                  z '.title', @model.l.get 'place.details'
                  @$details

              # z '.section',
              #   z '.title', @model.l.get 'placeInfo.location'
              #   z '.map',
              #     style:
              #       backgroundImage:
              #         if place
              #           "url(#{config.USER_CDN_URL}/places/#{place.type}/#{place.id}_map.large.png)"

              z '.section',
                z '.title', @model.l.get 'placeInfo.contact'
                z @$contact

              if place?.type is 'amenity' and place.amenities?.indexOf('gas') isnt -1
                z '.section',
                  z 'img.image',
                    src: 'https://api.mapbox.com/styles/v1/mapbox/' +
                        'satellite-v9/static/pin-s-fuel+dbad49' +
                        "(#{place.location.lon},#{place.location.lat})/" +
                        "#{place.location.lon},#{place.location.lat},17,0.00," +
                        '0.00/320x320@2x?access_token=' +
                        "#{config.MAPBOX_ACCESS_TOKEN}"

              if place?.type is 'amenity'
                z '.section',
                  z '.title', @model.l.get 'placeInfo.features'
                  _map amenities, ({amenity, $icon}) =>
                    z '.amenity',
                      z '.icon',
                        z $icon,
                          icon: amenity
                          isTouchTarget: false
                          size: '16px'
                          color: colors["$icon#{amenity}"]

                      z '.name', @model.l.get "amenities.#{amenity}"

              unless _isEmpty cellCarriers
                z '.section',
                  z '.title', @model.l.get 'campground.cellSignal'
                  z '.carriers', {
                    ontouchstart: (e) ->
                      e.stopPropagation()
                  },
                    _map cellCarriers, ({$bars, carrier}) =>
                      z '.carrier',
                        z '.bars',
                          z $bars, widthPx: cellBarsWidthPx
                        z '.name', @model.l.get "carriers.#{carrier}"

              if place?.weather
                z '.section',
                  z @$placeInfoWeather

              if place?.crowds?[season]?.value or place?.safety?.value
                z '.section',
                  z '.title', @model.l.get 'placeInfo.seasonalScales'

                  if place?.crowds?[season] or place?.fullness?[season]
                    z '.seasons',
                       _map @seasons, ({key, text}) =>
                         isSelected = season is key
                         z '.tap-tab', {
                           className: z.classKebab {isSelected}
                           onclick: =>
                             @state.set {season: key}
                         },
                           text

                  if place?.crowds?[season]
                    z '.scale',
                      z '.title', @model.l.get 'campground.crowds'
                      z @$crowdsInfoLevel, {
                        value: place?.crowds[season]
                        hideNumbers: true
                      }
                  if place?.fullness?[season]
                    z '.scale',
                      z '.title', @model.l.get 'campground.fullness'
                      z @$fullnessInfoLevel, {
                        value: place?.fullness[season]
                        hideNumbers: true
                      }
                  if place?.noise?['day']
                    z '.scale',
                      z '.title', @model.l.get 'campground.noise'
                      z @$noiseInfoLevel, {
                        value: place?.noise['day']
                        hideNumbers: true
                      }
                  if place?.shade?.value
                    z '.scale',
                      z '.title', @model.l.get 'campground.shade'
                      z @$shadeInfoLevel, {
                        value: place?.shade
                        hideNumbers: true
                      }
                  if place?.cleanliness?.value
                    z '.scale',
                      z '.title', @model.l.get 'campground.cleanliness'
                      z @$cleanlinessInfoLevel, {
                        value: place?.cleanliness
                        hideNumbers: true
                        isReversed: true # 5 is bad 1 is good
                      }
                  if place?.safety?.value
                    z '.scale',
                      z '.title', @model.l.get 'campground.safety'
                      z @$safetyInfoLevel, {
                        value: place?.safety
                        hideNumbers: true
                        isReversed: true # 5 is bad 1 is good
                      }
                  if place?.roadDifficulty?.value
                    z '.scale',
                      z '.title', @model.l.get 'campground.roadDifficulty'
                      z @$roadDifficultyInfoLevel, {
                        value: place?.roadDifficulty
                        hideNumbers: true
                      }

                    # TODO: icons for pets (paw), padSurface (road), entryType (car-brake-parking), allowedTypes, maxDays?,
                    # hasFreshWater (water), hasSewage (poop), has30Amp (power-plug), has50Amp, maxLength (rule), restrooms (toilet)?

              unless _isEmpty features
                z '.section',
                  z '.title', @model.l.get 'placeInfo.features'
                  z '.features.g-grid',
                    z '.g-cols',
                      _map features, ({feature, icon, $icon}) =>
                        z '.feature.g-col.g-xs-6.g-md-6',
                          z '.icon',
                            z $icon,
                              icon: icon
                              isTouchTarget: false
                              size: '18px'
                              color: colors.$bgText87
                          @model.l.get "feature.#{feature}"


              unless _isEmpty $videos
                z '.section',
                  z '.title', @model.l.get 'general.videos'
                  z '.videos'
                    _map $videos, ($video) ->
                      z $video
            ]

      z '.spinner', z @$spinner
