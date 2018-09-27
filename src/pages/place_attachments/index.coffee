z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
PlaceAttachments = require '../../components/place_attachments'
BasePage = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceAttachmentsPage extends BasePage
  hideDrawer: true

  constructor: (options) ->
    {@model, @router, requests, serverData,
      group, @isOverlayed, overlay$} = options

    @place = @clearOnUnmount requests.switchMap ({route}) =>
      type = route.src.split('/')[1]
      type = if type in ['campground', 'amenity'] then type else 'campground'
      @model[type].getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$placeAttachments = new PlaceAttachments {
      @model, @router, @place, overlay$
    }

    @state = z.state
      me: @model.user.getMe()
      place: @place
      windowSize: @model.window.getSize()

  getMeta: ->
    @place.map (place) ->
      {
        title: "Boondocking #{place?.name} pictures"
      }

  render: =>
    {me, place, windowSize} = @state.getValue()

    z '.p-place-attachments', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: @model.l.get 'placeAttachmentsPage.title', {
          replacements:
            name: place?.name
        }
        isFlat: true
        style: 'primary'
        $topLeftButton: z @$buttonBack, {
          @isOverlayed, color: colors.$header500Icon
        }
      }
      @$placeAttachments
