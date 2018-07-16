z = require 'zorium'

colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class AppBar
  constructor: ({@model}) -> null

  getHeight: =>
    @model.window.getAppBarHeight()

  render: (options) ->
    {$topLeftButton, $topRightButton, title, bgColor, color, isFlat,
      style, isFullWidth} = options

    color ?= colors.$header500Text
    bgColor ?= colors.$header500

    z 'header.z-app-bar', {
      className: z.classKebab {isFlat}
    },
      z '.bar', {
        style:
          backgroundColor: bgColor
      },
        z '.wrapper', {
          className: z.classKebab {
            gGrid: not isFullWidth
          }
        },
          z '.top',
            if $topLeftButton
              z '.top-left-button', {
                style:
                  color: color
              },
                $topLeftButton
            z '.title', {
              style:
                color: color
            }, title
            z '.top-right-button', {
              style:
                color: color
            },
              $topRightButton
