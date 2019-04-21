z = require 'zorium'

ButtonBack = require '../button_back'
AppBar = require '../app_bar'
Tabs = require '../tabs'
FormattedText = require '../formatted_text'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class PlaceInfoDetailsOverlay
  constructor: ({@model, @router, title, text}) ->
    @$buttonBack = new ButtonBack {@router}
    @$appBar = new AppBar {@model}

    @$details = new FormattedText {
      text: text
      imageWidth: 'auto'
      isFullWidth: true
      embedVideos: false
      @model
      @router
      # truncate:
      #   maxLength: 250
      #   height: 200
    }

    @state = z.state
      title: title
      windowSize: @model.window.getSize()

  render: =>
    {title, windowSize} = @state.getValue()

    z '.z-place-info-details-overlay',
      z @$appBar, {
        title: title
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
          onclick: =>
            @model.overlay.close()
        }
      }

      z '.content',
        @$details
