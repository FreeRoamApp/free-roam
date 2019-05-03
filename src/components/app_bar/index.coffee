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
      isFullWidth} = options

    color ?= if isPrimary then colors.$primary500Text else colors.$header500Text
    bgColor ?= if isPrimary then colors.$primary500 else colors.$header500

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
          z '.top.g-grid',
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
