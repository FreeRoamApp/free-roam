z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Place = require '../../components/place'
BasePage = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlacePage extends BasePage
  hideDrawer: true

  constructor: (options) ->
    {@model, @router, requests, serverData,
      group, @isOverlayed} = options

    @place = @clearOnUnmount requests.switchMap ({route}) =>
      type = route.src.split('/')[1]
      type = if type in ['campground', 'amenity'] then type else 'campground'
      @model[type].getBySlug route.params.slug

    tab = requests.map ({route}) ->
      route.params.tab

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$place = new Place {@model, @router, @place, tab}

    @state = z.state
      me: @model.user.getMe()
      place: @place
      windowSize: @model.window.getSize()

  getMeta: ->
    @place.map (place) ->
      {
        title: "Boondocking #{place?.name}"
      }

  render: =>
    {me, place, windowSize} = @state.getValue()

    z '.p-place', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: place?.name
        isFlat: true
        style: 'primary'
        $topLeftButton: z @$buttonBack, {
          @isOverlayed, color: colors.$header500Icon
        }
      }
      @$place
