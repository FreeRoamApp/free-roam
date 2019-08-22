z = require 'zorium'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class AppBar
  constructor: ({@model}) -> null

  getHeight: =>
    @model.window.getAppBarHeight()

  render: (options) ->
    {$topLeftButton, $topRightButton, title, bgColor, color, isFlat, isPrimary
      isSecondary, isFullWidth} = options

    if isPrimary
      color ?= colors.$primary500Text
      bgColor ?= colors.$primary500
    else if isSecondary
      color ?= colors.$secondary500Text
      bgColor ?= colors.$secondary500
    else
      color ?= colors.$header500Text
      bgColor ?= colors.$header500

    z 'header.z-app-bar', {
      className: z.classKebab {isFlat}
    },
      z '.bar', {
        style:
          backgroundColor: bgColor
      },
        z '.top.g-grid.overflow-visible',
          if $topLeftButton
            z '.top-left-button', {
              style:
                color: color
            },
              $topLeftButton
          z 'h1.title', {
            style:
              color: color
          }, title
          z '.top-right-button', {
            style:
              color: color
          },
            $topRightButton
