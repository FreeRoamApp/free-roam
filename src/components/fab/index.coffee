z = require 'zorium'

Ripple = require '../ripple'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class Fab
  constructor: ->
    @$ripple = new Ripple()

  render: ({$icon, colors, isMini, onclick}) =>
    isMini ?= false
    colors ?= {
      c500: colors.$black
    }

    z '.z-fab', {
      className: z.classKebab {isMini}
      style:
        backgroundColor: colors.c500
    },
      z '.icon-container',
        $icon
      z @$ripple,
        onComplete: onclick
