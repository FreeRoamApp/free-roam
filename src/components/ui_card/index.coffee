_map = require 'lodash/map'
z = require 'zorium'

FlatButton = require '../flat_button'
PushService = require '../../services/push'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class UiCard
  constructor: ->
    @$cancelButton = new FlatButton()
    @$idkButton = new FlatButton()
    @$submitButton = new FlatButton()

    # @state = z.state {}

  render: (props) =>
    # {state} = @state.getValue()
    {minHeightPx, isHighlighted, $title, $content, cancel, idk, submit} = props

    z '.z-ui-card', {
      className: z.classKebab {isHighlighted}
      style:
        if minHeightPx
          minHeight: "#{minHeightPx}px"
    },
      if $title
        z '.title', $title
      z '.text', $content
      z '.buttons',
        if cancel
          z 'div',
            z @$cancelButton,
              text: cancel.text
              isFullWidth: false
              onclick: cancel.onclick
        if idk
          z 'div',
            z @$idkButton,
              text: idk.text
              isFullWidth: false
              onclick: idk.onclick
        if submit
          z 'div',
            z @$submitButton,
              text: submit.text
              isFullWidth: false
              onclick: submit.onclick
              colors:
                cText: colors.$primary500
