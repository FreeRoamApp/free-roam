z = require 'zorium'
_startCase = require 'lodash/startCase'

RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
BasePage = require '../base'
Icon = require '../../components/icon'
Environment = require '../../services/environment'
ReviewThanksDialog = require '../../components/review_thanks_dialog'
RequestRating = require '../../components/request_rating'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

MIN_PLACE_PAGE_COUNT_TO_SHOW = 3

module.exports = class PlacePage extends BasePage
  hideDrawer: true

  constructor: (options) ->
    {@model, @router, requests, serverData, group} = options

    @place = @clearOnUnmount requests.switchMap ({route}) =>
      if route.params.slug is 'cache-shell'
        RxObservable.of null
      else
        @placeModel.getBySlug route.params.slug

    tripId = requests.map ({req}) =>
      req.query.tripId
    trip = tripId.switchMap (tripId) =>
      if tripId
        @model.trip.getById tripId
      else
        RxObservable.of null

    tab = requests.map ({route}) ->
      route.params.tab

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$place = new @Place {@model, @router, @place, tab, trip}
    @$editIcon = new Icon()
    @$deleteIcon = new Icon()

    @state = z.state
      me: @model.user.getMe()
      place: @place
      tripId: tripId

  getMeta: =>
    @place.map (place) =>
      {
        title: @model.l.get 'placePage.title', {replacements: name: place?.name}
        description: @model.l.get 'placePage.description', {
          replacements:
            name: place?.name
            location: "#{place?.address?.locality}, #{place?.address?.administrativeArea}"
        }
        structuredData:
          type: 'LocalBusiness'
          name: place?.name
          ratingValue: place?.rating
          ratingCount: place?.ratingCount
      }

  beforeUnmount: =>
    placesViewed = localStorage.placesViewed or 0
    localStorage.placesViewed = parseInt(placesViewed) + 1
    if not localStorage.hasSeenRequestRating and
        localStorage.placesViewed >= MIN_PLACE_PAGE_COUNT_TO_SHOW and
        Environment.isNativeApp 'freeroam'
      @model.overlay.open new RequestRating {@model}

  render: =>
    {me, place, tripId} = @state.getValue()

    z '.p-place',
      z @$appBar, {
        title: @title
        isFlat: true
        isSecondary: Boolean tripId
        $topLeftButton: z @$buttonBack, {
          color: if tripId \
                 then colors.$secondary500Text
                 else colors.$header500Icon
        }
        $topRightButton:
          if me?.username in ['austin', 'big_boxtruck', 'roadpickle', 'rachel']
            z '.p-place_top-right',
              z @$editIcon,
                icon: 'edit'
                color: colors.$header500Icon
                hasRipple: true
                onclick: =>
                  @router.go "edit#{_startCase(place.type)}", {
                    slug: place.slug
                  }
              z @$deleteIcon,
                icon: 'delete'
                color: colors.$header500Icon
                hasRipple: true
                onclick: =>
                  if confirm 'Are you sure?'
                    @placeModel.deleteByRow place
                    .then =>
                      @router.go 'home'
      }
      @$place
