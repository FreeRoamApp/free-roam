z = require 'zorium'

AppBar = require '../app_bar'
ButtonBack = require '../button_back'
CoordinatePicker = require '../coordinate_picker'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class CoordinatePickerOverlay
  constructor: (options) ->
    {@model, @router} = options

    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@router}

    @$coordinatePicker = new CoordinatePicker options

  render: =>
    z '.z-coordinate-picker-overlay',
      z @$appBar, {
        title: @model.l.get 'coordinatePicker.title'
        $topLeftButton: z @$buttonBack, {
          color: colors.$header500Icon
          onclick: =>
            @model.overlay.close()
        }
      }
      z @$coordinatePicker
