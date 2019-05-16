z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

Fab = require '../fab'
Icon = require '../icon'
PlaceInfo = require '../place_info'
PlaceNearby = require '../place_nearby'
PlaceReviews = require '../place_reviews'
Tabs = require '../tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Place
  constructor: ({@model, @router, place, @tab}) ->
    me = @model.user.getMe()

    @selectedIndex = new RxBehaviorSubject 0

    @$fab = new Fab()
    @$addIcon = new Icon()
    @$tabs = new Tabs {@model, @selectedIndex}

    @$placeInfo = new PlaceInfo {@model, @router, place}
    @$reviews = new PlaceReviews {@model, @router, place}
    @$nearby = new PlaceNearby {
      @model, @router, place
      isActive: @selectedIndex.map (index) -> index is 2
    }

    # @$reviewsTooltip = new Tooltip {
    #   @model
    #   key: 'placeReviews'
    #   # anchor: 'top-left'
    #   offset:
    #     left: 48
    # }

    @state = z.state
      selectedIndex: @selectedIndex
      place: place

  afterMount: =>
    @disposable = @selectedIndex.subscribe (tabIndex) ->
      ga? 'send', 'event', 'place', 'tab', tabIndex
    @tab.take(1).subscribe (tab) =>
      if tab is 'reviews'
        @selectedIndex.next 1

  beforeUnmount: =>
    @selectedIndex.next 0
    @disposable?.unsubscribe()

  render: =>
    {place, selectedIndex} = @state.getValue()

    z '.z-place',
      z @$tabs,
        isBarFixed: false
        tabs: [
          {
            $menuText: @model.l.get 'general.info'
            $el: @$placeInfo
          }
          {
            $menuText: @model.l.get 'general.reviews'
            $el: @$reviews
            # FIXME: only show if reviews exist...
            $tooltip: @$placeReviews
          }
          {
            $menuText: @model.l.get 'general.nearby'
            $el: @$nearby
          }
        ]

      if selectedIndex is 1 # reviews
        z '.fab',
          z @$fab,
            colors:
              c500: colors.$primary500
            $icon: z @$addIcon, {
              icon: 'add'
              isTouchTarget: false
              color: colors.$primary500Text
            }
            onclick: =>
              console.log 'click', @newReviewPath
              @router.go @newReviewPath, {
                slug: place.slug
              }, {ignoreHistory: true}
