z = require 'zorium'

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
      @placeModel.getBySlug route.params.slug

    tab = requests.map ({route}) ->
      route.params.tab

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$place = new @Place {@model, @router, @place, tab}
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
          if me?.username is 'austin'
            z @$deleteIcon,
              icon: 'delete'
              color: colors.$header500Icon
              hasRipple: true
              onclick: =>
                if confirm 'Confirm?'
                  @placeModel.deleteByRow place
                  .then =>
                    @router.go 'home'
      }
      @$place
