z = require 'zorium'
colors = require '../../colors'

Icon = require '../icon'

if window?
  require './index.styl'

module.exports = class ButtonMenu
  constructor: ({@model}) ->
    @$menuIcon = new Icon()

  render: ({color, onclick} = {}) =>
    z '.z-button-menu',
      z @$menuIcon,
        isAlignedLeft: true
        icon: 'menu'
        color: color or colors.$header500Icon
        hasRipple: true
        onclick: (e) =>
          e.preventDefault()
          if onclick
            onclick()
          else
            @model.drawer.open()
