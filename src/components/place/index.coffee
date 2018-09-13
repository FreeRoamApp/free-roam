z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'
_map = require 'lodash/map'

Fab = require '../fab'
Icon = require '../icon'
CampgroundInfo = require '../campground_info'
PlaceReviews = require '../place_reviews'
Tabs = require '../tabs'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class Place
  constructor: ({@model, @router, place}) ->
    me = @model.user.getMe()

    selectedIndex = new RxBehaviorSubject 0

    @$fab = new Fab()
    @$addIcon = new Icon()
    @$tabs = new Tabs {@model, selectedIndex}
    @$placeInfo = new CampgroundInfo {@model, @router, place}
    @$placeReviews = new PlaceReviews {@model, @router, place}

    @state = z.state
      selectedIndex: selectedIndex
      place: place

  render: =>
    {place, selectedIndex} = @state.getValue()

    z '.z-place',
      z @$tabs,
        isBarFixed: false
        hasAppBar: true
        tabs: [
          {
            $menuText: @model.l.get 'general.info'
            $el: @$placeInfo
          }
          {
            $menuText: @model.l.get 'general.reviews'
            $el: @$placeReviews
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
              }
