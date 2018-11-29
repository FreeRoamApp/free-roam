z = require 'zorium'
_defaults = require 'lodash/defaults'

Button = require '../button'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class SecondaryButton extends Button
  render: (opts) ->
    z '.z-secondary-button',
      super _defaults opts, {
        isFullWidth: true
        isRaised: true
        isDark: true
        colors:
          c200: colors.$tertiary200
          c500: colors.$tertiary100
          c600: colors.$tertiary300
          c700: colors.$tertiary400
          ink: colors.$primary900
      }
