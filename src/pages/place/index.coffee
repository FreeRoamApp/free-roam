z = require 'zorium'
_startCase = require 'lodash/startCase'

RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/of'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
BasePage = require '../base'
Icon = require '../../components/icon'
ReviewThanksDialog = require '../../components/review_thanks_dialog'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacePage extends BasePage
  hideDrawer: true

  constructor: (options) ->
    {@model, @router, requests, serverData,
      group} = options

    @place = @clearOnUnmount requests.switchMap ({route}) =>
      if route.params.slug is 'shell'
        RxObservable.of null
      else
        @placeModel.getBySlug route.params.slug

    tab = requests.map ({route}) ->
      route.params.tab

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$place = new @Place {@model, @router, @place, tab}
    @$editIcon = new Icon()
    @$deleteIcon = new Icon()

    @state = z.state
      me: @model.user.getMe()
      place: @place

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

  render: =>
    {me, place} = @state.getValue()

    z '.p-place',
      z @$appBar, {
        title: place?.name
        isFlat: true
        style: 'primary'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
        }
        $topRightButton:
          if me?.username in ['austin', 'big_boxtruck', 'roadpickle']
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
