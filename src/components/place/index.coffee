z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

Fab = require '../fab'
Icon = require '../icon'
CampgroundInfo = require '../campground_info'
CampgroundNearby = require '../campground_nearby'
Reviews = require '../reviews'
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

    # TODO: PlaceInfo? or select appropriate component here
    @$placeInfo = new CampgroundInfo {@model, @router, place}
    @$reviews = new Reviews {@model, @router, parent: place}

    # TODO PlaceNearby
    @$nearby = new CampgroundNearby {@model, @router, place}

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
              @router.go 'campgroundNewReview', {
                slug: place.slug
              }, {ignoreHistory: true}
