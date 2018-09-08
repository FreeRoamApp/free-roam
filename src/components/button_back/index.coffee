z = require 'zorium'
colors = require '../../colors'

Icon = require '../icon'

module.exports = class ButtonBack
  constructor: ({@router}) ->
    @$backIcon = new Icon()

  render: ({color, onclick, fallbackPath, isOverlayed} = {}) =>
    z '.z-button-back',
      z @$backIcon,
        isAlignedLeft: true
        icon: 'back'
        color: color or colors.$header500Icon
        hasRipple: true
        onclick: (e) =>
          e.preventDefault()
          setImmediate =>
            if isOverlayed
              @router.overlayPage$.next null
              window.history.back()
            else if onclick
              onclick()
            else
              @router.back {fallbackPath}
