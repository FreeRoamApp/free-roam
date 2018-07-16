_map = require 'lodash/map'
z = require 'zorium'

FlatButton = require '../flat_button'
PushService = require '../../services/push'

if window?
  require './index.styl'

module.exports = class UiCard
  constructor: ->
    @$cancelButton = new FlatButton()
    @$submitButton = new FlatButton()

    @state = z.state {
      state: 'ask'
    }

  render: ({minHeightPx, isHighlighted, $title, $content, cancel, submit}) =>
    {state} = @state.getValue()

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
        if submit
          z 'div',
            z @$submitButton,
              text: submit.text
              isFullWidth: false
              onclick: submit.onclick
