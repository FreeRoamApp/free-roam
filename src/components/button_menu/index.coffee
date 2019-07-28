z = require 'zorium'
colors = require '../../colors'

Icon = require '../icon'

if window?
  require './index.styl'

module.exports = class ButtonMenu
  constructor: ({@model}) ->
    @$menuIcon = new Icon()

  isVisible: ->
    # TODO: json file with vars that are used in stylus and js
    # eg $breakPointLarge
    not window?.matchMedia('(min-width: 1280px)').matches

  render: ({color, onclick, isAlignedLeft} = {}) =>
    isAlignedLeft ?= true
    z '.z-button-menu',
      z @$menuIcon,
        isAlignedLeft: isAlignedLeft
        icon: 'menu'
        color: color or colors.$header500Icon
        hasRipple: true
        onclick: (e) =>
          e.preventDefault()
          if onclick
            onclick()
          else
            @model.drawer.open()
