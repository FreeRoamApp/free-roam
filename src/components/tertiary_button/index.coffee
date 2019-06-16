z = require 'zorium'
_defaults = require 'lodash/defaults'

Button = require '../button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class TertiaryButton extends Button
  render: (opts) ->
    z '.z-tertiary-button',
      super _defaults opts, {
        isFullWidth: true
        isRaised: true
        isDark: true
        colors:
          c200: colors.$bgText54
          c500: colors.$bgText87
          c600: colors.$bgText100
          c700: colors.$bgText100
          ink: colors.$tertiary0
      }
