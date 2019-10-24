z = require 'zorium'
_defaults = require 'lodash/defaults'

Icon = require '../icon'
Ripple = require '../ripple'
allColors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Fab
  constructor: ->
    @$icon = new Icon()
    @$ripple = new Ripple()

  render: (props) =>
    {icon, colors, isPrimary, isSecondary, onclick, isImmediate, sizePx} = props

    sizePx ?= 56

    colors = _defaults colors, {
      c500: if isPrimary then allColors.$primaryMain \
            else if isSecondary then allColors.$secondaryMain
            else allColors.$white
      cText: if isPrimary then allColors.$primaryMainText \
            else if isSecondary then allColors.$secondaryMainText
            else allColors.$bgText87
      ripple: allColors.$white
    }

    z '.z-fab', {
      onclick: if isImmediate then onclick
      style:
        backgroundColor: colors.c500
        width: "#{sizePx}px"
        height: "#{sizePx}px"
    },
      z '.icon-container',
        z @$icon,
          icon: icon
          isTouchTarget: false
          color: colors.cText
      z @$ripple,
        onComplete: if not isImmediate then onclick
        color: colors.ripple
