z = require 'zorium'

Ripple = require '../ripple'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Fab
  constructor: ->
    @$ripple = new Ripple()

  render: ({$icon, colors, isMini, onclick, isImmediate}) =>
    isMini ?= false
    colors ?= {
      c500: colors.$black
      ripple: colors.$white
    }

    z '.z-fab', {
      className: z.classKebab {isMini}
      onclick: if isImmediate then onclick
      style:
        backgroundColor: colors.c500
    },
      z '.icon-container',
        $icon
      z @$ripple,
        onComplete: if not isImmediate then onclick
        color: colors.ripple
