z = require 'zorium'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'
_isEmpty = require 'lodash/isEmpty'
_filter = require 'lodash/filter'

CellBars = require '../cell_bars'
Icon = require '../icon'
InfoLevelTabs = require '../info_level_tabs'
InfoLevel = require '../info_level'
EmbeddedVideo = require '../embedded_video'
MasonryGrid = require '../masonry_grid'
Spinner = require '../spinner'
Rating = require '../rating'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class CampgroundInfo
  constructor: ({@model, @router, place}) ->
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
      value: place.map (place) -> place?.rating
    }
    @$spinner = new Spinner()

    @state = z.state
      attachments: place.switchMap (place) =>
        unless place
          return RxObservable.of null
        @model.campgroundAttachment.getAllByParentId place.id
      place: place.map (place) =>
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

  render: =>
    {place, attachments} = @state.getValue()

    {place, $videos, cellCarriers} = place or {}

    # spinner as a class so the dom structure stays the same between loads
    isLoading = not place?.slug
    z '.z-campground-info', {className: z.classKebab {isLoading}},
      unless _isEmpty attachments
        z '.cover', {
          style:
            backgroundImage:
              "url(#{attachments[0].largeSrc})"
        },
          @router.link z 'a.see-more', {
            href: @router.get 'campgroundAttachments', {
              slug: place?.slug
            }
          },
            @model.l.get 'campgroundInfo.seeAll', {
              replacements: {count: attachments.length}
            }
      z '.g-grid',
        z '.location',
          "#{place?.address?.locality}, #{place?.address?.administrativeArea}"
          ' ('
          z 'a', {
            href:
              'https://maps.google.com/?saddr=My+Location&daddr=' +
              place?.location?.lat + ',' + place?.location?.lon
            target: '_system'
          }, @model.l.get 'general.directions'
          ')'

        z '.rating',
          z @$rating, {size: '20px'}

        if place?.drivingInstructions
          z '.driving-instructions',
            z '.title', @model.l.get 'campground.drivingInstructions'
            place?.drivingInstructions

        z '.masonry',
          z @$masonryGrid,
            columnCounts:
              mobile: 1
              desktop: 2
              tablet: 2
            $elements: _filter [
              z '.section',
                z '.title', @model.l.get 'campground.cellSignal'
                z '.carriers',
                  _map cellCarriers, ({$bars, carrier, type}) =>
                    z '.carrier',
                      z '.name', @model.l.get "carriers.#{carrier}"
                      z '.bars',
                        z $bars, widthPx: 40
                      z '.type', type

              z '.section',
                z '.title', @model.l.get 'campground.crowds'
                z @$crowdsInfoLevelTabs, {
                  value: place?.crowds
                  min: 1
                  max: 5
                }
              z '.section',
                z '.title', @model.l.get 'campground.fullness'
                z @$fullnessInfoLevelTabs, {
                  value: place?.fullness
                  min: 1
                  max: 5
                }
              z '.section',
                z '.title', @model.l.get 'campground.noise'
                z @$noiseInfoLevelTabs, {
                  value: place?.noise
                  min: 1
                  max: 5
                }
              z '.section',
                z '.title', @model.l.get 'campground.shade'
                z @$shadeInfoLevel, {
                  value: place?.shade
                  min: 1
                  max: 5
                }
              z '.section',
                z '.title', @model.l.get 'campground.safety'
                z @$safetyInfoLevel, {
                  value: place?.safety
                  min: 1
                  max: 5
                  isReversed: true # 5 is bad 1 is good
                }
              z '.section',
                z '.title', @model.l.get 'campground.roadDifficulty'
                z @$roadDifficultyInfoLevel, {
                  value: place?.roadDifficulty
                  min: 1
                  max: 5
                }

              z '.section',
                z '.title', @model.l.get 'campgroundInfo.averageWeather'
                z 'img.graph', {
                  src:
                    "#{config.USER_CDN_URL}/weather/campground_#{place?.id}.svg?12"
                }

              unless _isEmpty $videos
                z '.section',
                  z '.title', @model.l.get 'general.videos'
                  z '.videos'
                    _map $videos, ($video) ->
                      z $video
            ]

      z '.spinner', z @$spinner
