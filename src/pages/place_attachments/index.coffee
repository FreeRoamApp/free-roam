z = require 'zorium'

AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
BasePage = require '../base'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceAttachmentsPage extends BasePage
  hideDrawer: true

  constructor: (options) ->
    {@model, @router, requests, serverData,
      group} = options

    @place = @clearOnUnmount requests.switchMap ({route}) =>
      @placeModel.getBySlug route.params.slug

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$placeAttachments = new @PlaceAttachments {
      @model, @router, @place
    }

    @state = z.state
      me: @model.user.getMe()
      place: @place
      windowSize: @model.window.getSize()

  getMeta: =>
    @place.map (place) =>
      {
        title: @model.l.get 'placeAttachmentsPage.title', {
          replacements:
            name: place?.name
          }
      }

  render: =>
    {me, place, windowSize} = @state.getValue()

    z '.p-place-attachments', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title:
          if place
            @model.l.get 'placeAttachmentsPage.title', {
              replacements:
                name: place?.name
            }
        isFlat: true
        style: 'primary'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
        }
      }
      @$placeAttachments
